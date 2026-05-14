package api

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	apimiddleware "cursorubcar/backend/internal/api/middleware"
	"cursorubcar/backend/internal/domain"
	"cursorubcar/backend/internal/repository"
	"cursorubcar/backend/internal/service"
	"github.com/google/uuid"
	"google.golang.org/api/idtoken"
)

type Server struct {
	postgres       *repository.PostgresRepository
	mongo          *repository.MongoRepository
	cache          *repository.CacheRepository
	auth           *service.AuthService
	googleClientID string
	validator      Validator
}

type contextKey string

const authUserKey contextKey = "auth_user"

const maxJSONBodySize = 1 << 20
const maxLoggedBodySize = 8 << 10

func NewServer(
	postgres *repository.PostgresRepository,
	mongo *repository.MongoRepository,
	cache *repository.CacheRepository,
	auth *service.AuthService,
	googleClientID string,
) *Server {
	return &Server{
		postgres:       postgres,
		mongo:          mongo,
		cache:          cache,
		auth:           auth,
		googleClientID: strings.TrimSpace(googleClientID),
		validator:      Validator{},
	}
}

func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("/health", s.handleHealth)
	mux.HandleFunc("/api/v1/auth/signup", s.handleSignup)
	mux.HandleFunc("/api/v1/auth/login", s.handleLogin)
	mux.HandleFunc("/api/v1/auth/google", s.handleGoogleAuth)
	mux.HandleFunc("/api/v1/auth/refresh", s.handleRefreshToken)
	mux.HandleFunc("/api/v1/auth/forgot-password", s.handleForgotPassword)
	mux.Handle("/api/v1/auth/me", s.authMiddleware(http.HandlerFunc(s.handleMe)))
	mux.Handle("/api/v1/auth/logout", s.authMiddleware(http.HandlerFunc(s.handleLogout)))
	mux.Handle("/api/v1/discover/routes", s.authMiddleware(http.HandlerFunc(s.handleDiscoverRoutes)))
	mux.Handle("/api/v1/routes", s.authMiddleware(http.HandlerFunc(s.handleRoutes)))
	mux.Handle("/api/v1/trips/demo-request", s.authMiddleware(http.HandlerFunc(s.handleDemoRideRequest)))
	mux.Handle("/api/v1/trips", s.authMiddleware(http.HandlerFunc(s.handleTrips)))
	mux.Handle("/api/v1/trips/", s.authMiddleware(http.HandlerFunc(s.handleTripStatus)))
	mux.Handle("/api/v1/chat/", s.authMiddleware(http.HandlerFunc(s.handleChat)))
	mux.Handle("/api/v1/drivers/", s.authMiddleware(http.HandlerFunc(s.handleDrivers)))
	mux.Handle("/api/v1/users/", s.authMiddleware(http.HandlerFunc(s.handleUsers)))

	return s.withCORS(s.withLogging(apimiddleware.RateLimit(120, time.Minute)(mux)))
}

type authRequest struct {
	Name            string `json:"name"`
	Email           string `json:"email"`
	Password        string `json:"password"`
	Role            string `json:"role"`
	PhoneNumber     string `json:"phoneNumber"`
	Gender          string `json:"gender"`
	Age             int    `json:"age"`
	CarModel        string `json:"carModel"`
	CarPlate        string `json:"carPlate"`
	DriverLicenseID string `json:"driverLicenseId"`
}

type googleAuthRequest struct {
	IDToken         string `json:"idToken"`
	IDTokenAlt      string `json:"id_token"`
	GoogleIDToken   string `json:"googleIdToken"`
	Role            string `json:"role"`
	PhoneNumber     string `json:"phoneNumber"`
	Gender          string `json:"gender"`
	Age             int    `json:"age"`
	CarModel        string `json:"carModel"`
	CarPlate        string `json:"carPlate"`
	DriverLicenseID string `json:"driverLicenseId"`
}

type forgotPasswordRequest struct {
	Email       string `json:"email"`
	NewPassword string `json:"newPassword"`
}

type refreshTokenRequest struct {
	RefreshToken string `json:"refreshToken"`
}

type routePayload struct {
	ID        string   `json:"id"`
	From      string   `json:"from"`
	To        string   `json:"to"`
	Midpoints []string `json:"midpoints"`
}

type createTripRequest struct {
	PassengerID     string       `json:"passengerId"`
	PassengerName   string       `json:"passengerName"`
	PassengerRating float64      `json:"passengerRating"`
	DriverID        string       `json:"driverId"`
	Route           routePayload `json:"route"`
	SeatsRequested  int          `json:"seatsRequested"`
}

type updateTripStatusRequest struct {
	Status string `json:"status"`
}

type saveRouteRequest struct {
	UserID string       `json:"userId"`
	Route  routePayload `json:"route"`
}

type createChatRequest struct {
	SenderID string `json:"senderId"`
	Message  string `json:"message"`
}

type updateLocationRequest struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Heading   float64 `json:"heading"`
}

type discoverRouteResponse struct {
	Route              domain.SavedRoute `json:"route"`
	Driver             domain.User       `json:"driver"`
	ActiveTripCount    int               `json:"activeTripCount"`
	CompletedTripCount int               `json:"completedTripCount"`
}

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
	body       bytes.Buffer
}

func (w *loggingResponseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}

func (w *loggingResponseWriter) Write(body []byte) (int, error) {
	if w.statusCode == 0 {
		w.statusCode = http.StatusOK
	}
	if w.body.Len() < maxLoggedBodySize {
		remaining := maxLoggedBodySize - w.body.Len()
		if len(body) > remaining {
			_, _ = w.body.Write(body[:remaining])
		} else {
			_, _ = w.body.Write(body)
		}
	}
	return w.ResponseWriter.Write(body)
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.methodNotAllowed(w)
		return
	}
	s.writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *Server) handleSignup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}

	var req authRequest
	if err := s.decodeJSON(r, &req); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.Role = normalizeRole(req.Role)
	if req.Name == "" || req.Email == "" || req.Password == "" {
		s.writeError(w, http.StatusBadRequest, "name, email, and password are required")
		return
	}
	if err := s.validator.ValidateEmail(req.Email); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := s.validator.ValidatePassword(req.Password); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if err := s.validator.ValidateUserProfile(req.Role, req.PhoneNumber, req.Gender, req.Age, req.CarModel, req.CarPlate, req.DriverLicenseID); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	passwordHash, err := s.auth.HashPassword(req.Password)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to hash password")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	user := domain.User{
		Name:            req.Name,
		Email:           req.Email,
		PasswordHash:    passwordHash,
		Role:            req.Role,
		PhoneNumber:     strings.TrimSpace(req.PhoneNumber),
		Gender:          normalizeGender(req.Gender),
		Age:             req.Age,
		CarModel:        strings.TrimSpace(req.CarModel),
		CarPlate:        strings.TrimSpace(req.CarPlate),
		DriverLicenseID: strings.TrimSpace(req.DriverLicenseID),
		CreatedAt:       time.Now().UTC(),
	}

	saved, err := s.postgres.CreateUser(ctx, user)
	if err != nil {
		s.writeError(w, http.StatusConflict, "email already exists or user creation failed")
		return
	}

	token, err := s.auth.IssueToken(ctx, saved)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to issue token")
		return
	}

	saved.PasswordHash = ""
	s.writeJSON(w, http.StatusCreated, map[string]any{
		"token": token,
		"user":  saved,
	})
}

func (s *Server) handleGoogleAuth(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}
	if s.googleClientID == "" {
		s.writeError(w, http.StatusServiceUnavailable, "google auth is not configured")
		return
	}

	var req googleAuthRequest
	if err := s.decodeJSON(r, &req); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	req.IDToken = firstNonEmpty(req.IDToken, req.IDTokenAlt, req.GoogleIDToken)
	req.IDToken = strings.TrimSpace(req.IDToken)
	if req.IDToken == "" {
		s.writeError(w, http.StatusBadRequest, "idToken is required")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	payload, err := validateGoogleIDToken(ctx, req.IDToken, s.googleClientID)
	if err != nil {
		s.writeError(w, http.StatusUnauthorized, "invalid google token")
		return
	}

	email, _ := payload.Claims["email"].(string)
	email = strings.ToLower(strings.TrimSpace(email))
	if email == "" || s.validator.ValidateEmail(email) != nil {
		s.writeError(w, http.StatusUnauthorized, "google account email is not available")
		return
	}

	if !googleEmailVerified(payload.Claims["email_verified"]) {
		s.writeError(w, http.StatusUnauthorized, "google account email is not verified")
		return
	}

	name, _ := payload.Claims["name"].(string)
	name = strings.TrimSpace(name)
	if name == "" {
		name = strings.Split(email, "@")[0]
	}

	user, err := s.postgres.GetUserByEmail(ctx, email)
	if err != nil && !errors.Is(err, repository.ErrNotFound) {
		s.writeError(w, http.StatusInternalServerError, "failed to load user")
		return
	}

	if errors.Is(err, repository.ErrNotFound) {
		role := normalizeRole(req.Role)
		if role == "" {
			role = "passenger"
		}
		if err := s.validator.ValidateUserProfile(role, req.PhoneNumber, req.Gender, req.Age, req.CarModel, req.CarPlate, req.DriverLicenseID); err != nil {
			s.writeError(w, http.StatusBadRequest, err.Error())
			return
		}

		fallbackPasswordHash, hashErr := s.auth.HashPassword("google-" + payload.Subject)
		if hashErr != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to create account")
			return
		}

		user = domain.User{
			Name:            name,
			Email:           email,
			PasswordHash:    fallbackPasswordHash,
			Role:            role,
			PhoneNumber:     strings.TrimSpace(req.PhoneNumber),
			Gender:          normalizeGender(req.Gender),
			Age:             req.Age,
			CarModel:        strings.TrimSpace(req.CarModel),
			CarPlate:        strings.TrimSpace(req.CarPlate),
			DriverLicenseID: strings.TrimSpace(req.DriverLicenseID),
			CreatedAt:       time.Now().UTC(),
		}

		user, err = s.postgres.CreateUser(ctx, user)
		if err != nil {
			s.writeError(w, http.StatusConflict, "failed to create google user")
			return
		}
	}

	token, err := s.auth.IssueToken(ctx, user)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to issue token")
		return
	}

	user.PasswordHash = ""
	s.writeJSON(w, http.StatusOK, map[string]any{
		"token": token,
		"user":  user,
	})
}

func (s *Server) handleForgotPassword(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}

	var req forgotPasswordRequest
	if err := s.decodeJSON(r, &req); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	email := strings.ToLower(strings.TrimSpace(req.Email))
	if email == "" || s.validator.ValidateEmail(email) != nil {
		s.writeError(w, http.StatusBadRequest, "valid email is required")
		return
	}
	if err := s.validator.ValidatePassword(req.NewPassword); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	passwordHash, err := s.auth.HashPassword(req.NewPassword)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to reset password")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	updated, err := s.postgres.UpdateUserPasswordByEmail(ctx, email, passwordHash)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to reset password")
		return
	}

	if !updated {
		s.writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
		return
	}

	s.writeJSON(w, http.StatusOK, map[string]string{"status": "password_updated"})
}

func (s *Server) handleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}

	var req authRequest
	if err := s.decodeJSON(r, &req); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	email := strings.ToLower(strings.TrimSpace(req.Email))
	if email == "" || req.Password == "" {
		s.writeError(w, http.StatusBadRequest, "email and password are required")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	user, err := s.postgres.GetUserByEmail(ctx, email)
	if err != nil {
		s.writeError(w, http.StatusUnauthorized, "invalid credentials")
		return
	}
	if err := s.auth.ComparePassword(user.PasswordHash, req.Password); err != nil {
		s.writeError(w, http.StatusUnauthorized, "invalid credentials")
		return
	}

	token, err := s.auth.IssueToken(ctx, user)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to issue token")
		return
	}

	user.PasswordHash = ""
	s.writeJSON(w, http.StatusOK, map[string]any{
		"token": token,
		"user":  user,
	})
}

func (s *Server) handleRefreshToken(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}

	var req refreshTokenRequest
	if err := s.decodeJSON(r, &req); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	req.RefreshToken = strings.TrimSpace(req.RefreshToken)
	if req.RefreshToken == "" {
		s.writeError(w, http.StatusBadRequest, "refreshToken is required")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	token, err := s.auth.RefreshToken(ctx, req.RefreshToken)
	if err != nil {
		s.writeError(w, http.StatusUnauthorized, "invalid refresh token")
		return
	}

	s.writeJSON(w, http.StatusOK, map[string]any{"token": token})
}

func (s *Server) handleMe(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.methodNotAllowed(w)
		return
	}

	user, ok := authUserFromContext(r.Context())
	if !ok {
		s.writeError(w, http.StatusUnauthorized, "missing user in context")
		return
	}

	s.writeJSON(w, http.StatusOK, map[string]domain.User{"user": user})
}

func (s *Server) handleLogout(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}

	token := bearerToken(r.Header.Get("Authorization"))
	if token == "" {
		s.writeError(w, http.StatusUnauthorized, "missing bearer token")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	claims, err := s.auth.ParseToken(ctx, token)
	if err != nil {
		s.writeError(w, http.StatusUnauthorized, "invalid token")
		return
	}
	if err := s.auth.RevokeToken(ctx, claims.ID); err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to revoke token")
		return
	}

	s.writeJSON(w, http.StatusOK, map[string]string{"status": "logged_out"})
}

func (s *Server) handleRoutes(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		user, _ := authUserFromContext(r.Context())
		userID := r.URL.Query().Get("userId")
		if userID == "" {
			userID = user.ID
		}
		if userID != user.ID {
			s.writeError(w, http.StatusForbidden, "cannot read another user's routes")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		routes, err := s.postgres.ListSavedRoutesByUser(ctx, userID)
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to list routes")
			return
		}
		s.writeJSON(w, http.StatusOK, map[string]any{"routes": routes})

	case http.MethodPost:
		var req saveRouteRequest
		if err := s.decodeJSON(r, &req); err != nil {
			s.writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		if req.UserID == "" || req.Route.From == "" || req.Route.To == "" {
			s.writeError(w, http.StatusBadRequest, "userId and route are required")
			return
		}
		user, _ := authUserFromContext(r.Context())
		if req.UserID != user.ID {
			s.writeError(w, http.StatusForbidden, "cannot save routes for another user")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		route := domain.SavedRoute{
			ID:        req.Route.ID,
			UserID:    req.UserID,
			From:      req.Route.From,
			To:        req.Route.To,
			Midpoints: sanitizeMidpoints(req.Route.Midpoints),
			CreatedAt: time.Now().UTC(),
		}
		saved, err := s.postgres.CreateSavedRoute(ctx, route)
		if err != nil {
			log.Printf("save route error user_id=%s route_id=%s err=%v", req.UserID, req.Route.ID, err)
			s.writeError(w, http.StatusInternalServerError, "failed to save route")
			return
		}
		s.writeJSON(w, http.StatusCreated, map[string]any{"route": saved})

	default:
		s.methodNotAllowed(w)
	}
}

func (s *Server) handleDiscoverRoutes(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.methodNotAllowed(w)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	routes, err := s.postgres.ListAllSavedRoutes(ctx)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to list discover routes")
		return
	}

	responses := make([]discoverRouteResponse, 0, len(routes))
	for _, route := range routes {
		driver, err := s.postgres.GetUserByID(ctx, route.UserID)
		if err != nil {
			continue
		}
		if driver.Role != "driver" {
			continue
		}
		driver.PasswordHash = ""

		driverTrips, err := s.mongo.ListTripsByUser(ctx, driver.ID)
		if err != nil {
			driverTrips = nil
		}
		activeTrips := 0
		completedTrips := 0
		for _, trip := range driverTrips {
			if trip.DriverID != driver.ID {
				continue
			}
			if trip.Status == "completed" {
				completedTrips++
			}
			if trip.Status == "active" || trip.Status == "accepted" {
				activeTrips++
			}
		}

		responses = append(responses, discoverRouteResponse{
			Route:              route,
			Driver:             driver,
			ActiveTripCount:    activeTrips,
			CompletedTripCount: completedTrips,
		})
	}

	s.writeJSON(w, http.StatusOK, map[string]any{"routes": responses})
}

func (s *Server) handleTrips(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		user, _ := authUserFromContext(r.Context())
		userID := r.URL.Query().Get("userId")
		if userID == "" {
			userID = user.ID
		}
		if userID != user.ID {
			s.writeError(w, http.StatusForbidden, "cannot read another user's trips")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

		trips, err := s.mongo.ListTripsByUser(ctx, userID)
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to list trips")
			return
		}
		s.writeJSON(w, http.StatusOK, map[string]any{"trips": trips})

	case http.MethodPost:
		var req createTripRequest
		if err := s.decodeJSON(r, &req); err != nil {
			s.writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		if req.PassengerID == "" || req.Route.From == "" || req.Route.To == "" {
			s.writeError(w, http.StatusBadRequest, "passengerId and route are required")
			return
		}
		user, _ := authUserFromContext(r.Context())
		if user.Role != "passenger" {
			s.writeError(w, http.StatusForbidden, "only passengers can create trips")
			return
		}
		if req.PassengerID != user.ID {
			s.writeError(w, http.StatusForbidden, "cannot create trips for another passenger")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

		trip := domain.Trip{
			PassengerID:     req.PassengerID,
			PassengerName:   strings.TrimSpace(req.PassengerName),
			PassengerRating: normalizeRating(req.PassengerRating),
			DriverID:        req.DriverID,
			Route: domain.SavedRoute{
				ID:        req.Route.ID,
				UserID:    req.DriverID,
				From:      req.Route.From,
				To:        req.Route.To,
				Midpoints: sanitizeMidpoints(req.Route.Midpoints),
				CreatedAt: time.Now().UTC(),
			},
			Status:         "active",
			SeatsRequested: normalizeSeatCount(req.SeatsRequested),
			CreatedAt:      time.Now().UTC(),
		}

		created, err := s.mongo.CreateTrip(ctx, trip)
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to create trip")
			return
		}
		_ = s.cache.CacheTripStatus(ctx, created.ID, created.Status, 24*time.Hour)
		s.writeJSON(w, http.StatusCreated, map[string]any{"trip": created})

	default:
		s.methodNotAllowed(w)
	}
}

func (s *Server) handleDemoRideRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}

	var req createTripRequest
	if err := s.decodeJSON(r, &req); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if req.Route.From == "" || req.Route.To == "" {
		s.writeError(w, http.StatusBadRequest, "route is required")
		return
	}

	user, _ := authUserFromContext(r.Context())
	if user.Role != "driver" {
		s.writeError(w, http.StatusForbidden, "only drivers can create demo ride requests")
		return
	}

	passengerID := strings.TrimSpace(req.PassengerID)
	if passengerID == "" {
		passengerID = "passenger-demo-001"
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	trip := domain.Trip{
		PassengerID:     passengerID,
		PassengerName:   firstNonEmpty(strings.TrimSpace(req.PassengerName), "Demo Passenger"),
		PassengerRating: normalizeRating(req.PassengerRating),
		DriverID:        user.ID,
		Route: domain.SavedRoute{
			ID:        req.Route.ID,
			UserID:    user.ID,
			From:      req.Route.From,
			To:        req.Route.To,
			Midpoints: sanitizeMidpoints(req.Route.Midpoints),
			CreatedAt: time.Now().UTC(),
		},
		Status:         "active",
		SeatsRequested: normalizeSeatCount(req.SeatsRequested),
		CreatedAt:      time.Now().UTC(),
	}

	created, err := s.mongo.CreateTrip(ctx, trip)
	if err != nil {
		s.writeError(w, http.StatusInternalServerError, "failed to create demo ride request")
		return
	}
	_ = s.cache.CacheTripStatus(ctx, created.ID, created.Status, 24*time.Hour)
	s.writeJSON(w, http.StatusCreated, map[string]any{"trip": created})
}

func (s *Server) handleTripStatus(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPatch {
		s.methodNotAllowed(w)
		return
	}

	parts := strings.Split(strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/v1/trips/"), "/"), "/")
	if len(parts) != 2 || parts[1] != "status" {
		http.NotFound(w, r)
		return
	}

	var req updateTripStatusRequest
	if err := s.decodeJSON(r, &req); err != nil {
		s.writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if req.Status == "" {
		s.writeError(w, http.StatusBadRequest, "status is required")
		return
	}
	if !isAllowedTripStatus(req.Status) {
		s.writeError(w, http.StatusBadRequest, "invalid trip status")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

	user, _ := authUserFromContext(r.Context())
	existingTrip, err := s.mongo.GetTripByID(ctx, parts[0])
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			s.writeError(w, http.StatusNotFound, "trip not found")
			return
		}
		s.writeError(w, http.StatusInternalServerError, "failed to load trip")
		return
	}
	if existingTrip.DriverID != user.ID && existingTrip.PassengerID != user.ID {
		s.writeError(w, http.StatusForbidden, "cannot update another user's trip")
		return
	}

	updated, err := s.mongo.UpdateTripStatus(ctx, parts[0], req.Status)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			s.writeError(w, http.StatusNotFound, "trip not found")
			return
		}
		s.writeError(w, http.StatusInternalServerError, "failed to update trip")
		return
	}

	_ = s.cache.CacheTripStatus(ctx, updated.ID, updated.Status, 24*time.Hour)
	s.writeJSON(w, http.StatusOK, map[string]any{"trip": updated})
}

func (s *Server) handleChat(w http.ResponseWriter, r *http.Request) {
	tripID := strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/v1/chat/"), "/")
	if tripID == "" {
		http.NotFound(w, r)
		return
	}

	switch r.Method {
	case http.MethodGet:
		ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

		user, _ := authUserFromContext(r.Context())
		trip, err := s.mongo.GetTripByID(ctx, tripID)
		if err != nil {
			if errors.Is(err, repository.ErrNotFound) {
				s.writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			s.writeError(w, http.StatusInternalServerError, "failed to load trip")
			return
		}
		if trip.DriverID != user.ID && trip.PassengerID != user.ID {
			s.writeError(w, http.StatusForbidden, "cannot read another trip's chat")
			return
		}

		messages, err := s.mongo.ListChatMessages(ctx, tripID)
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to list messages")
			return
		}
		s.writeJSON(w, http.StatusOK, map[string]any{"messages": messages})

	case http.MethodPost:
		var req createChatRequest
		if err := s.decodeJSON(r, &req); err != nil {
			s.writeError(w, http.StatusBadRequest, err.Error())
			return
		}
		if req.SenderID == "" || strings.TrimSpace(req.Message) == "" {
			s.writeError(w, http.StatusBadRequest, "senderId and message are required")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

		user, _ := authUserFromContext(r.Context())
		if req.SenderID != user.ID {
			s.writeError(w, http.StatusForbidden, "cannot send chat as another user")
			return
		}
		trip, err := s.mongo.GetTripByID(ctx, tripID)
		if err != nil {
			if errors.Is(err, repository.ErrNotFound) {
				s.writeError(w, http.StatusNotFound, "trip not found")
				return
			}
			s.writeError(w, http.StatusInternalServerError, "failed to load trip")
			return
		}
		if trip.DriverID != user.ID && trip.PassengerID != user.ID {
			s.writeError(w, http.StatusForbidden, "cannot send chat to another trip")
			return
		}

		message := domain.ChatMessage{
			TripID:    tripID,
			SenderID:  req.SenderID,
			Message:   strings.TrimSpace(req.Message),
			CreatedAt: time.Now().UTC(),
		}

		saved, err := s.mongo.CreateChatMessage(ctx, message)
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to send message")
			return
		}
		s.writeJSON(w, http.StatusCreated, map[string]any{"message": saved})

	default:
		s.methodNotAllowed(w)
	}
}

func (s *Server) handleDrivers(w http.ResponseWriter, r *http.Request) {
	parts := strings.Split(strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/v1/drivers/"), "/"), "/")
	if len(parts) != 2 {
		http.NotFound(w, r)
		return
	}

	driverID := parts[0]
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	switch parts[1] {
	case "profile":
		if r.Method != http.MethodGet {
			s.methodNotAllowed(w)
			return
		}

		driver, err := s.postgres.GetUserByID(ctx, driverID)
		if err != nil {
			if errors.Is(err, repository.ErrNotFound) {
				s.writeError(w, http.StatusNotFound, "driver not found")
				return
			}
			s.writeError(w, http.StatusInternalServerError, "failed to get driver profile")
			return
		}
		if driver.Role != "driver" {
			s.writeError(w, http.StatusNotFound, "driver not found")
			return
		}
		driver.PasswordHash = ""
		s.writeJSON(w, http.StatusOK, map[string]any{"driver": driver})

	case "location":
		switch r.Method {
		case http.MethodGet:
			location, err := s.cache.DriverLocation(ctx, driverID)
			if err != nil {
				if errors.Is(err, repository.ErrNotFound) {
					s.writeError(w, http.StatusNotFound, "driver location not found")
					return
				}
				s.writeError(w, http.StatusInternalServerError, "failed to get location")
				return
			}
			s.writeJSON(w, http.StatusOK, map[string]any{"location": location})

		case http.MethodPut:
			var req updateLocationRequest
			if err := s.decodeJSON(r, &req); err != nil {
				s.writeError(w, http.StatusBadRequest, err.Error())
				return
			}

			user, _ := authUserFromContext(r.Context())
			if user.Role != "driver" {
				s.writeError(w, http.StatusForbidden, "only drivers can update location")
				return
			}
			if user.ID != driverID {
				s.writeError(w, http.StatusForbidden, "cannot update another driver's location")
				return
			}
			if req.Latitude < -90 || req.Latitude > 90 || req.Longitude < -180 || req.Longitude > 180 {
				s.writeError(w, http.StatusBadRequest, "invalid latitude or longitude")
				return
			}

			location := domain.DriverLocation{
				DriverID:   driverID,
				Latitude:   req.Latitude,
				Longitude:  req.Longitude,
				Heading:    req.Heading,
				RecordedAt: time.Now().UTC(),
			}

			if err := s.cache.SaveDriverLocation(ctx, location, 5*time.Minute); err != nil {
				s.writeError(w, http.StatusInternalServerError, "failed to save location")
				return
			}
			s.writeJSON(w, http.StatusOK, map[string]any{"location": location})

		default:
			s.methodNotAllowed(w)
		}

	default:
		http.NotFound(w, r)
	}
}

func (s *Server) handleUsers(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		s.methodNotAllowed(w)
		return
	}

	userID := strings.Trim(strings.TrimPrefix(r.URL.Path, "/api/v1/users/"), "/")
	if userID == "" {
		http.NotFound(w, r)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

	user, err := s.postgres.GetUserByID(ctx, userID)
	if err != nil {
		if errors.Is(err, repository.ErrNotFound) {
			s.writeError(w, http.StatusNotFound, "user not found")
			return
		}
		s.writeError(w, http.StatusInternalServerError, "failed to get user profile")
		return
	}

	user.PasswordHash = ""
	s.writeJSON(w, http.StatusOK, map[string]any{"user": user})
}

func (s *Server) authMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token := bearerToken(r.Header.Get("Authorization"))
		if token == "" {
			s.writeError(w, http.StatusUnauthorized, "missing bearer token")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		claims, err := s.auth.ParseToken(ctx, token)
		if err != nil {
			s.writeError(w, http.StatusUnauthorized, "invalid token")
			return
		}

		user, err := s.postgres.GetUserByID(ctx, claims.Subject)
		if err != nil {
			s.writeError(w, http.StatusUnauthorized, "user not found")
			return
		}

		user.PasswordHash = ""
		next.ServeHTTP(w, r.WithContext(context.WithValue(r.Context(), authUserKey, user)))
	})
}

func authUserFromContext(ctx context.Context) (domain.User, bool) {
	user, ok := ctx.Value(authUserKey).(domain.User)
	return user, ok
}

func isAllowedTripStatus(status string) bool {
	switch status {
	case "active", "accepted", "completed", "cancelled":
		return true
	default:
		return false
	}
}

func normalizeSeatCount(seats int) int {
	if seats < 1 {
		return 1
	}
	if seats > 7 {
		return 7
	}
	return seats
}

func normalizeRating(rating float64) float64 {
	if rating <= 0 {
		return 4.8
	}
	if rating > 5 {
		return 5
	}
	return rating
}

func sanitizeMidpoints(midpoints []string) []string {
	if len(midpoints) == 0 {
		return []string{}
	}

	cleaned := make([]string, 0, len(midpoints))
	for _, midpoint := range midpoints {
		trimmed := strings.TrimSpace(midpoint)
		if trimmed != "" {
			cleaned = append(cleaned, trimmed)
		}
	}
	if len(cleaned) == 0 {
		return []string{}
	}

	return cleaned
}

func (s *Server) decodeJSON(r *http.Request, dst any) error {
	defer r.Body.Close()

	decoder := json.NewDecoder(io.LimitReader(r.Body, maxJSONBodySize))
	// Intentionally allow unknown fields so the mobile client can evolve request
	// payloads without breaking older backend builds.

	if err := decoder.Decode(dst); err != nil {
		if errors.Is(err, io.EOF) {
			return errors.New("request body is required")
		}
		return errors.New("invalid request body")
	}

	var extra any
	if err := decoder.Decode(&extra); err != io.EOF {
		return errors.New("request body must contain a single JSON object")
	}

	return nil
}

func bearerToken(header string) string {
	if header == "" {
		return ""
	}
	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	return strings.TrimSpace(parts[1])
}

func (s *Server) writeJSON(w http.ResponseWriter, status int, payload any) {
	requestID := uuid.NewString()
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Request-ID", requestID)
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(SuccessResponse{
		Data:      payload,
		Timestamp: time.Now().UTC(),
		RequestID: requestID,
	})
}

func (s *Server) writeError(w http.ResponseWriter, status int, message string) {
	requestID := uuid.NewString()
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Request-ID", requestID)
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(ErrorResponse{
		Code:      http.StatusText(status),
		Message:   message,
		Timestamp: time.Now().UTC(),
		RequestID: requestID,
	})
}

func (s *Server) methodNotAllowed(w http.ResponseWriter) {
	s.writeError(w, http.StatusMethodNotAllowed, "method not allowed")
}

func (s *Server) withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, OPTIONS")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		w.Header().Set("Referrer-Policy", "no-referrer")
		w.Header().Set("Cache-Control", "no-store")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		startedAt := time.Now()

		var requestBody []byte
		if r.Body != nil {
			body, err := io.ReadAll(r.Body)
			if err != nil {
				log.Printf("HTTP %s %s request_body_read_error=%v", r.Method, r.URL.Path, err)
				s.writeError(w, http.StatusBadRequest, "failed to read request body")
				return
			}
			requestBody = body
			r.Body = io.NopCloser(bytes.NewReader(body))
		}

		writer := &loggingResponseWriter{ResponseWriter: w}
		next.ServeHTTP(writer, r)

		statusCode := writer.statusCode
		if statusCode == 0 {
			statusCode = http.StatusOK
		}

		log.Printf(
			"HTTP %s %s status=%d duration=%s remote=%s query=%q auth=%s request=%s response=%s",
			r.Method,
			r.URL.Path,
			statusCode,
			time.Since(startedAt).Round(time.Millisecond),
			r.RemoteAddr,
			r.URL.RawQuery,
			maskAuthorizationHeader(r.Header.Get("Authorization")),
			sanitizeLoggedBody(requestBody),
			sanitizeLoggedBody(writer.body.Bytes()),
		)
	})
}

func sanitizeLoggedBody(body []byte) string {
	if len(body) == 0 {
		return "[empty]"
	}

	body = bytes.TrimSpace(body)
	if len(body) == 0 {
		return "[empty]"
	}

	var payload any
	if err := json.Unmarshal(body, &payload); err == nil {
		maskedPayload := maskSensitiveValue(payload)
		maskedJSON, marshalErr := json.Marshal(maskedPayload)
		if marshalErr == nil {
			return truncateForLog(string(maskedJSON))
		}
	}

	return truncateForLog(string(body))
}

func maskSensitiveValue(value any) any {
	switch typed := value.(type) {
	case map[string]any:
		masked := make(map[string]any, len(typed))
		for key, nestedValue := range typed {
			if isSensitiveField(key) {
				masked[key] = "[redacted]"
				continue
			}
			masked[key] = maskSensitiveValue(nestedValue)
		}
		return masked
	case []any:
		masked := make([]any, len(typed))
		for index, item := range typed {
			masked[index] = maskSensitiveValue(item)
		}
		return masked
	default:
		return value
	}
}

func isSensitiveField(field string) bool {
	switch strings.ToLower(strings.TrimSpace(field)) {
	case "password", "newpassword", "passwordhash", "password_hash", "token", "idtoken", "accesstoken", "access_token", "authorization", "jwt":
		return true
	default:
		return false
	}
}

func normalizeRole(role string) string {
	return strings.ToLower(strings.TrimSpace(role))
}

func normalizeGender(gender string) string {
	return strings.ToLower(strings.TrimSpace(gender))
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if strings.TrimSpace(value) != "" {
			return value
		}
	}
	return ""
}

func splitGoogleClientIDs(raw string) []string {
	parts := strings.Split(raw, ",")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			out = append(out, trimmed)
		}
	}
	return out
}

func validateGoogleIDToken(ctx context.Context, token, rawClientIDs string) (*idtoken.Payload, error) {
	clientIDs := splitGoogleClientIDs(rawClientIDs)
	if len(clientIDs) == 0 {
		return nil, errors.New("google auth is not configured")
	}

	var lastErr error
	for _, clientID := range clientIDs {
		payload, err := idtoken.Validate(ctx, token, clientID)
		if err == nil {
			return payload, nil
		}
		lastErr = err
	}

	if lastErr != nil {
		return nil, lastErr
	}
	return nil, errors.New("invalid google token")
}

func googleEmailVerified(value any) bool {
	switch typed := value.(type) {
	case bool:
		return typed
	case string:
		return strings.EqualFold(strings.TrimSpace(typed), "true")
	default:
		return false
	}
}

func maskAuthorizationHeader(header string) string {
	if strings.TrimSpace(header) == "" {
		return "[empty]"
	}

	parts := strings.SplitN(header, " ", 2)
	if len(parts) != 2 {
		return "[redacted]"
	}
	return parts[0] + " [redacted]"
}

func truncateForLog(value string) string {
	if len(value) <= maxLoggedBodySize {
		return value
	}
	return value[:maxLoggedBodySize] + "...[truncated]"
}

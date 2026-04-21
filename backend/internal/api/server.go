package api

import (
	"context"
	"encoding/json"
	"errors"
	"log"
	"net/http"
	"strings"
	"time"

	"cursorubcar/backend/internal/domain"
	"cursorubcar/backend/internal/repository"
	"cursorubcar/backend/internal/service"
)

type Server struct {
	postgres *repository.PostgresRepository
	mongo    *repository.MongoRepository
	cache    *repository.CacheRepository
	auth     *service.AuthService
}

type contextKey string

const authUserKey contextKey = "auth_user"

func NewServer(
	postgres *repository.PostgresRepository,
	mongo *repository.MongoRepository,
	cache *repository.CacheRepository,
	auth *service.AuthService,
) *Server {
	return &Server{
		postgres: postgres,
		mongo:    mongo,
		cache:    cache,
		auth:     auth,
	}
}

func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("/health", s.handleHealth)
	mux.HandleFunc("/api/v1/auth/signup", s.handleSignup)
	mux.HandleFunc("/api/v1/auth/login", s.handleLogin)
	mux.Handle("/api/v1/auth/me", s.authMiddleware(http.HandlerFunc(s.handleMe)))
	mux.Handle("/api/v1/auth/logout", s.authMiddleware(http.HandlerFunc(s.handleLogout)))
	mux.Handle("/api/v1/routes", s.authMiddleware(http.HandlerFunc(s.handleRoutes)))
	mux.Handle("/api/v1/trips", s.authMiddleware(http.HandlerFunc(s.handleTrips)))
	mux.Handle("/api/v1/trips/", s.authMiddleware(http.HandlerFunc(s.handleTripStatus)))
	mux.Handle("/api/v1/chat/", s.authMiddleware(http.HandlerFunc(s.handleChat)))
	mux.Handle("/api/v1/drivers/", s.authMiddleware(http.HandlerFunc(s.handleDrivers)))

	return s.withCORS(s.withLogging(mux))
}

type authRequest struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
	Role     string `json:"role"`
}

type routePayload struct {
	ID   string `json:"id"`
	From string `json:"from"`
	To   string `json:"to"`
}

type createTripRequest struct {
	PassengerID string       `json:"passengerId"`
	DriverID    string       `json:"driverId"`
	Route       routePayload `json:"route"`
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

type errorResponse struct {
	Error string `json:"error"`
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
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Email = strings.ToLower(strings.TrimSpace(req.Email))
	req.Role = strings.TrimSpace(req.Role)
	if req.Name == "" || req.Email == "" || req.Password == "" {
		s.writeError(w, http.StatusBadRequest, "name, email, and password are required")
		return
	}
	if req.Role != "driver" && req.Role != "passenger" {
		s.writeError(w, http.StatusBadRequest, "role must be driver or passenger")
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
		Name:         req.Name,
		Email:        req.Email,
		PasswordHash: passwordHash,
		Role:         req.Role,
		CreatedAt:    time.Now().UTC(),
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

func (s *Server) handleLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.methodNotAllowed(w)
		return
	}

	var req authRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid request body")
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
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			s.writeError(w, http.StatusBadRequest, "invalid request body")
			return
		}
		if req.UserID == "" || req.Route.From == "" || req.Route.To == "" {
			s.writeError(w, http.StatusBadRequest, "userId and route are required")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		route := domain.SavedRoute{
			ID:        req.Route.ID,
			UserID:    req.UserID,
			From:      req.Route.From,
			To:        req.Route.To,
			CreatedAt: time.Now().UTC(),
		}
		saved, err := s.postgres.CreateSavedRoute(ctx, route)
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to save route")
			return
		}
		s.writeJSON(w, http.StatusCreated, map[string]any{"route": saved})

	default:
		s.methodNotAllowed(w)
	}
}

func (s *Server) handleTrips(w http.ResponseWriter, r *http.Request) {
	switch r.Method {
	case http.MethodGet:
		user, _ := authUserFromContext(r.Context())
		userID := r.URL.Query().Get("userId")
		if userID == "" {
			userID = user.ID
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
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			s.writeError(w, http.StatusBadRequest, "invalid request body")
			return
		}
		if req.PassengerID == "" || req.Route.From == "" || req.Route.To == "" {
			s.writeError(w, http.StatusBadRequest, "passengerId and route are required")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

		trip := domain.Trip{
			PassengerID: req.PassengerID,
			DriverID:    req.DriverID,
			Route: domain.SavedRoute{
				ID:        req.Route.ID,
				UserID:    req.DriverID,
				From:      req.Route.From,
				To:        req.Route.To,
				CreatedAt: time.Now().UTC(),
			},
			Status:    "active",
			CreatedAt: time.Now().UTC(),
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
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		s.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}
	if req.Status == "" {
		s.writeError(w, http.StatusBadRequest, "status is required")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
	defer cancel()

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

		messages, err := s.mongo.ListChatMessages(ctx, tripID)
		if err != nil {
			s.writeError(w, http.StatusInternalServerError, "failed to list messages")
			return
		}
		s.writeJSON(w, http.StatusOK, map[string]any{"messages": messages})

	case http.MethodPost:
		var req createChatRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			s.writeError(w, http.StatusBadRequest, "invalid request body")
			return
		}
		if req.SenderID == "" || strings.TrimSpace(req.Message) == "" {
			s.writeError(w, http.StatusBadRequest, "senderId and message are required")
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 10*time.Second)
		defer cancel()

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
	if len(parts) != 2 || parts[1] != "location" {
		http.NotFound(w, r)
		return
	}

	driverID := parts[0]
	ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
	defer cancel()

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
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			s.writeError(w, http.StatusBadRequest, "invalid request body")
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
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(payload)
}

func (s *Server) writeError(w http.ResponseWriter, status int, message string) {
	s.writeJSON(w, status, errorResponse{Error: message})
}

func (s *Server) methodNotAllowed(w http.ResponseWriter) {
	s.writeError(w, http.StatusMethodNotAllowed, "method not allowed")
}

func (s *Server) withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func (s *Server) withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s", r.Method, r.URL.Path)
		next.ServeHTTP(w, r)
	})
}

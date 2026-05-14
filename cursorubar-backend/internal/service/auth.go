package service

import (
	"context"
	"errors"
	"time"

	"cursorubcar/backend/internal/domain"
	"cursorubcar/backend/internal/repository"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type AuthService struct {
	secret []byte
	cache  *repository.CacheRepository
	users  *repository.PostgresRepository
}

const (
	tokenIssuer   = "cursorubcar-backend"
	tokenAudience = "cursorubcar-mobile"
	sessionTTL    = 7 * 24 * time.Hour
)

type Claims struct {
	Role  string `json:"role"`
	Email string `json:"email"`
	jwt.RegisteredClaims
}

type AuthToken struct {
	AccessToken string        `json:"accessToken"`
	TokenType   string        `json:"tokenType"`
	ExpiresIn   time.Duration `json:"expiresIn"`
	TokenID     string        `json:"-"`
}

func NewAuthService(secret string, cache *repository.CacheRepository, users *repository.PostgresRepository) *AuthService {
	return &AuthService{
		secret: []byte(secret),
		cache:  cache,
		users:  users,
	}
}

func (s *AuthService) HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func (s *AuthService) ComparePassword(hash, password string) error {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
}

func (s *AuthService) IssueToken(ctx context.Context, user domain.User) (AuthToken, error) {
	tokenID := uuid.NewString()
	now := time.Now().UTC()
	expiresAt := now.Add(sessionTTL)

	claims := Claims{
		Role:  user.Role,
		Email: user.Email,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    tokenIssuer,
			Audience:  []string{tokenAudience},
			Subject:   user.ID,
			ID:        tokenID,
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(s.secret)
	if err != nil {
		return AuthToken{}, err
	}

	if err := s.cache.SaveSession(ctx, tokenID, user.ID, sessionTTL); err != nil {
		return AuthToken{}, err
	}

	return AuthToken{
		AccessToken: signed,
		TokenType:   "Bearer",
		ExpiresIn:   sessionTTL,
		TokenID:     tokenID,
	}, nil
}

func (s *AuthService) ParseToken(ctx context.Context, signed string) (Claims, error) {
	token, err := jwt.ParseWithClaims(
		signed,
		&Claims{},
		func(token *jwt.Token) (any, error) {
			if token.Method == nil || token.Method.Alg() != jwt.SigningMethodHS256.Alg() {
				return nil, errors.New("unexpected signing method")
			}
			return s.secret, nil
		},
		jwt.WithIssuer(tokenIssuer),
		jwt.WithAudience(tokenAudience),
		jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
		jwt.WithExpirationRequired(),
	)
	if err != nil {
		return Claims{}, err
	}

	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid || claims.Subject == "" || claims.ID == "" {
		return Claims{}, errors.New("invalid token")
	}

	userID, err := s.cache.SessionUserID(ctx, claims.ID)
	if err != nil {
		return Claims{}, err
	}
	if userID != claims.Subject {
		return Claims{}, errors.New("invalid session")
	}

	return *claims, nil
}

func (s *AuthService) RevokeToken(ctx context.Context, tokenID string) error {
	return s.cache.DeleteSession(ctx, tokenID)
}

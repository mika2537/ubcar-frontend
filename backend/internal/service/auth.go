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
	accessTTL     = 15 * time.Minute
	refreshTTL    = 7 * 24 * time.Hour
)

type Claims struct {
	Role     string `json:"role"`
	Email    string `json:"email"`
	TokenUse string `json:"tokenUse"`
	jwt.RegisteredClaims
}

type AuthToken struct {
	AccessToken  string        `json:"accessToken"`
	RefreshToken string        `json:"refreshToken"`
	TokenType    string        `json:"tokenType"`
	ExpiresIn    time.Duration `json:"expiresIn"`
	TokenID      string        `json:"-"`
	RefreshID    string        `json:"-"`
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
	accessID := uuid.NewString()
	refreshID := uuid.NewString()
	now := time.Now().UTC()
	accessExpiresAt := now.Add(accessTTL)
	refreshExpiresAt := now.Add(refreshTTL)

	claims := Claims{
		Role:     user.Role,
		Email:    user.Email,
		TokenUse: "access",
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    tokenIssuer,
			Audience:  []string{tokenAudience},
			Subject:   user.ID,
			ID:        accessID,
			ExpiresAt: jwt.NewNumericDate(accessExpiresAt),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
		},
	}
	refreshClaims := Claims{
		TokenUse: "refresh",
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    tokenIssuer,
			Audience:  []string{tokenAudience},
			Subject:   user.ID,
			ID:        refreshID,
			ExpiresAt: jwt.NewNumericDate(refreshExpiresAt),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := token.SignedString(s.secret)
	if err != nil {
		return AuthToken{}, err
	}
	refreshToken := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims)
	refreshSigned, err := refreshToken.SignedString(s.secret)
	if err != nil {
		return AuthToken{}, err
	}

	if err := s.cache.SaveSession(ctx, accessID, user.ID, accessTTL); err != nil {
		return AuthToken{}, err
	}
	if err := s.cache.SaveSession(ctx, refreshID, user.ID, refreshTTL); err != nil {
		return AuthToken{}, err
	}

	return AuthToken{
		AccessToken:  signed,
		RefreshToken: refreshSigned,
		TokenType:    "Bearer",
		ExpiresIn:    accessTTL,
		TokenID:      accessID,
		RefreshID:    refreshID,
	}, nil
}

func (s *AuthService) ParseToken(ctx context.Context, signed string) (Claims, error) {
	return s.parseToken(ctx, signed, "access")
}

func (s *AuthService) RefreshToken(ctx context.Context, signed string) (AuthToken, error) {
	claims, err := s.parseToken(ctx, signed, "refresh")
	if err != nil {
		return AuthToken{}, err
	}

	user, err := s.users.GetUserByID(ctx, claims.Subject)
	if err != nil {
		return AuthToken{}, err
	}
	if err := s.cache.DeleteSession(ctx, claims.ID); err != nil {
		return AuthToken{}, err
	}
	return s.IssueToken(ctx, user)
}

func (s *AuthService) parseToken(ctx context.Context, signed, expectedUse string) (Claims, error) {
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
	if !ok || !token.Valid || claims.Subject == "" || claims.ID == "" || claims.TokenUse != expectedUse {
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

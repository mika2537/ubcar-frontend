package config

import (
	"errors"
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	Port           string
	PostgresDSN    string
	MongoURI       string
	MongoDatabase  string
	RedisAddr      string
	RedisPassword  string
	RedisDB        int
	JWTSecret      string
	GoogleClientID string
	SeedMockData   bool
}

func Load() (Config, error) {
	if err := godotenv.Load(".env"); err != nil && !errors.Is(err, os.ErrNotExist) {
		return Config{}, fmt.Errorf("failed to load .env: %w", err)
	}
	if err := godotenv.Overload(".env.local"); err != nil && !errors.Is(err, os.ErrNotExist) {
		return Config{}, fmt.Errorf("failed to load .env.local: %w", err)
	}

	cfg := Config{
		Port:           envOr("PORT", "172.16.155.28:8080"),
		PostgresDSN:    os.Getenv("POSTGRES_DSN"),
		MongoURI:       os.Getenv("MONGO_URI"),
		MongoDatabase:  envOr("MONGO_DATABASE", "ubcar"),
		RedisAddr:      envOr("REDIS_ADDR", "127.0.0.1:6379"),
		RedisPassword:  os.Getenv("REDIS_PASSWORD"),
		JWTSecret:      os.Getenv("JWT_SECRET"),
		GoogleClientID: strings.TrimSpace(os.Getenv("GOOGLE_CLIENT_ID")),
		SeedMockData:   envOr("SEED_MOCK_DATA", "true") == "true",
	}

	redisDB, err := strconv.Atoi(envOr("REDIS_DB", "0"))
	if err != nil {
		return Config{}, errors.New("REDIS_DB must be a number")
	}
	cfg.RedisDB = redisDB

	if cfg.PostgresDSN == "" {
		return Config{}, errors.New("POSTGRES_DSN is required")
	}
	if cfg.MongoURI == "" {
		return Config{}, errors.New("MONGO_URI is required")
	}
	if cfg.JWTSecret == "" {
		return Config{}, errors.New("JWT_SECRET is required")
	}

	return cfg, nil
}

func envOr(key, fallback string) string {
	value := os.Getenv(key)
	if value == "" {
		return fallback
	}
	return value
}

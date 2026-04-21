package repository

import (
	"context"
	"encoding/json"
	"time"

	"cursorubcar/backend/internal/domain"
	"github.com/redis/go-redis/v9"
)

type CacheRepository struct {
	client *redis.Client
}

func NewCacheRepository(addr, password string, db int) (*CacheRepository, error) {
	client := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		_ = client.Close()
		return nil, err
	}
	return &CacheRepository{client: client}, nil
}

func (r *CacheRepository) Close() error {
	return r.client.Close()
}

func (r *CacheRepository) SaveSession(ctx context.Context, tokenID, userID string, ttl time.Duration) error {
	return r.client.Set(ctx, sessionKey(tokenID), userID, ttl).Err()
}

func (r *CacheRepository) SessionUserID(ctx context.Context, tokenID string) (string, error) {
	userID, err := r.client.Get(ctx, sessionKey(tokenID)).Result()
	if err == redis.Nil {
		return "", ErrNotFound
	}
	return userID, err
}

func (r *CacheRepository) DeleteSession(ctx context.Context, tokenID string) error {
	return r.client.Del(ctx, sessionKey(tokenID)).Err()
}

func (r *CacheRepository) SaveDriverLocation(ctx context.Context, location domain.DriverLocation, ttl time.Duration) error {
	payload, err := json.Marshal(location)
	if err != nil {
		return err
	}
	return r.client.Set(ctx, driverLocationKey(location.DriverID), payload, ttl).Err()
}

func (r *CacheRepository) DriverLocation(ctx context.Context, driverID string) (domain.DriverLocation, error) {
	value, err := r.client.Get(ctx, driverLocationKey(driverID)).Result()
	if err == redis.Nil {
		return domain.DriverLocation{}, ErrNotFound
	}
	if err != nil {
		return domain.DriverLocation{}, err
	}

	var location domain.DriverLocation
	if err := json.Unmarshal([]byte(value), &location); err != nil {
		return domain.DriverLocation{}, err
	}
	return location, nil
}

func (r *CacheRepository) CacheTripStatus(ctx context.Context, tripID, status string, ttl time.Duration) error {
	return r.client.Set(ctx, tripStatusKey(tripID), status, ttl).Err()
}

func sessionKey(tokenID string) string {
	return "session:" + tokenID
}

func driverLocationKey(driverID string) string {
	return "driver_location:" + driverID
}

func tripStatusKey(tripID string) string {
	return "trip_status:" + tripID
}

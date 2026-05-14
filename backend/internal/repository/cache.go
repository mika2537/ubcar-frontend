package repository

import (
	"context"
	"crypto/tls"
	"encoding/json"
	"net"
	"os"
	"strings"
	"time"

	"cursorubcar/backend/internal/domain"
	"github.com/redis/go-redis/v9"
)

type CacheRepository struct {
	client *redis.Client
}

func NewCacheRepository(addr, password string, db int) (*CacheRepository, error) {
	opts := &redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	}
	if shouldUseRedisTLS(addr) {
		if host, _, err := net.SplitHostPort(addr); err == nil && host != "" {
			opts.TLSConfig = &tls.Config{
				MinVersion: tls.VersionTLS12,
				ServerName: host,
			}
		} else {
			opts.TLSConfig = &tls.Config{MinVersion: tls.VersionTLS12}
		}
	}

	client := redis.NewClient(opts)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := client.Ping(ctx).Err(); err != nil {
		_ = client.Close()
		return nil, err
	}
	return &CacheRepository{client: client}, nil
}

func shouldUseRedisTLS(addr string) bool {
	switch strings.ToLower(strings.TrimSpace(os.Getenv("REDIS_TLS"))) {
	case "1", "true", "yes", "y", "on":
		return true
	case "0", "false", "no", "n", "off":
		return false
	default:
		// Upstash (and many hosted redis providers) require TLS.
		return strings.Contains(strings.ToLower(addr), "upstash.io")
	}
}

func (r *CacheRepository) Close() error {
	return r.client.Close()
}

func (r *CacheRepository) GetOrSet(ctx context.Context, key string, fn func() (any, error), ttl time.Duration) (any, error) {
	value, err := r.client.Get(ctx, key).Result()
	if err == nil {
		var result any
		if err := json.Unmarshal([]byte(value), &result); err != nil {
			return nil, err
		}
		return result, nil
	}
	if err != redis.Nil {
		return nil, err
	}

	result, err := fn()
	if err != nil {
		return nil, err
	}

	payload, err := json.Marshal(result)
	if err != nil {
		return nil, err
	}
	return result, r.client.Set(ctx, key, payload, ttl).Err()
}

func (r *CacheRepository) InvalidatePattern(ctx context.Context, pattern string) error {
	var cursor uint64
	for {
		keys, nextCursor, err := r.client.Scan(ctx, cursor, pattern, 100).Result()
		if err != nil {
			return err
		}
		if len(keys) > 0 {
			if err := r.client.Del(ctx, keys...).Err(); err != nil {
				return err
			}
		}
		cursor = nextCursor
		if cursor == 0 {
			return nil
		}
	}
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

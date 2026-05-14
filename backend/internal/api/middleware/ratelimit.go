package middleware

import (
	"math"
	"net"
	"net/http"
	"strconv"
	"strings"
	"sync"
	"time"
)

type clientWindow struct {
	count    int
	resetAt  time.Time
	lastSeen time.Time
}

func RateLimit(maxRequests int, window time.Duration) func(http.Handler) http.Handler {
	if maxRequests <= 0 {
		maxRequests = 60
	}
	if window <= 0 {
		window = time.Minute
	}

	clients := map[string]*clientWindow{}
	var mu sync.Mutex

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			now := time.Now()
			key := clientIP(r)

			mu.Lock()
			for ip, state := range clients {
				if now.Sub(state.lastSeen) > 2*window {
					delete(clients, ip)
				}
			}

			state, ok := clients[key]
			if !ok || now.After(state.resetAt) {
				state = &clientWindow{resetAt: now.Add(window)}
				clients[key] = state
			}
			state.count++
			state.lastSeen = now
			allowed := state.count <= maxRequests
			retryAfter := int(math.Ceil(time.Until(state.resetAt).Seconds()))
			mu.Unlock()

			if !allowed {
				w.Header().Set("Retry-After", strconv.Itoa(retryAfter))
				http.Error(w, http.StatusText(http.StatusTooManyRequests), http.StatusTooManyRequests)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

func clientIP(r *http.Request) string {
	for _, header := range []string{"X-Forwarded-For", "X-Real-IP"} {
		value := strings.TrimSpace(r.Header.Get(header))
		if value == "" {
			continue
		}
		parts := strings.Split(value, ",")
		if ip := strings.TrimSpace(parts[0]); ip != "" {
			return ip
		}
	}

	host, _, err := net.SplitHostPort(r.RemoteAddr)
	if err == nil && host != "" {
		return host
	}
	return r.RemoteAddr
}

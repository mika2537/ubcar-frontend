# Backend API

This backend is now structured for the data split you described:

- Postgres: accounts, login users, saved route templates
- MongoDB: trips, chat messages, document-style ride data
- Redis: JWT session cache, live driver location, cached real-time trip status

## Folder layout

- `cmd/api/main.go`: app startup
- `internal/config`: environment config
- `internal/api`: HTTP handlers and middleware
- `internal/repository/postgres.go`: Postgres queries
- `internal/repository/mongo.go`: Mongo collections
- `internal/repository/cache.go`: Redis cache/session logic
- `internal/service/auth.go`: bcrypt password hashing and JWT auth

## Environment

Set these env vars before running:

```bash
export PORT=8080
export JWT_SECRET=change-this-secret
export POSTGRES_DSN="postgres://user:password@localhost:5433/ubcar?sslmode=disable"
export MONGO_URI="mongodb://localhost:27017"
export MONGO_DATABASE="ubcar"
export REDIS_ADDR="127.0.0.1:6379"
export REDIS_PASSWORD=""
export REDIS_DB=0
export SEED_MOCK_DATA=true
```

Or copy them into `.env.local` (recommended for local dev). The app loads `.env` first and then `.env.local` as an override.

## Run

```bash
go run ./cmd/api
```

If `SEED_MOCK_DATA=true`, startup will seed demo data into all three stores.

## API

### Auth

- `POST /api/v1/auth/signup`
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `POST /api/v1/auth/logout`

### Routes

- `GET /api/v1/routes?userId=...`
- `POST /api/v1/routes`

### Trips

- `GET /api/v1/trips?userId=...`
- `POST /api/v1/trips`
- `PATCH /api/v1/trips/{tripId}/status`

### Chat

- `GET /api/v1/chat/{tripId}`
- `POST /api/v1/chat/{tripId}`

### Driver real-time location

- `GET /api/v1/drivers/{driverId}/location`
- `PUT /api/v1/drivers/{driverId}/location`

## Mock data

Default demo login accounts:

- Driver 1: `driver@example.com` / `password123`
- Driver 2: `driver2@example.com` / `password123`
- Passenger: `passenger@example.com` / `password123`

Seeded Postgres data:

- users
- saved route templates
- saved route midpoints/stops

Seeded MongoDB data:

- trips: `trip-demo-001`, `trip-demo-002`
- chat messages: `chat-demo-001`, `chat-demo-002`, `chat-demo-003`

Seeded Redis data:

- live driver locations for `driver-demo-001` and `driver-demo-002`
- cached trip statuses for seeded trips

## Example signup payload

```json
{
  "name": "Driver One",
  "email": "driver1@example.com",
  "password": "password123",
  "role": "driver"
}
```

## Example login response

```json
{
  "token": {
    "accessToken": "jwt-token-here",
    "tokenType": "Bearer",
    "expiresIn": 604800000000000
  },
  "user": {
    "id": "uuid",
    "name": "Driver One",
    "email": "driver1@example.com",
    "role": "driver",
    "createdAt": "2026-04-16T00:00:00Z"
  }
}
```

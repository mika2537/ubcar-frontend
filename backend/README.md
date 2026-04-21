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
export POSTGRES_DSN="postgres://user:password@localhost:5432/ubcar?sslmode=disable"
export MONGO_URI="mongodb://localhost:27017"
export MONGO_DATABASE="ubcar"
export REDIS_ADDR="127.0.0.1:6379"
export REDIS_PASSWORD=""
export REDIS_DB=0
```

## Run

```bash
cd backend
go run ./cmd/api
```

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

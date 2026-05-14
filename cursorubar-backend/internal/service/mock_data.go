package service

import (
	"context"
	"time"

	"cursorubcar/backend/internal/domain"
	"cursorubcar/backend/internal/repository"
)

type MockSeedService struct {
	postgres *repository.PostgresRepository
	mongo    *repository.MongoRepository
	cache    *repository.CacheRepository
	auth     *AuthService
}

func NewMockSeedService(
	postgres *repository.PostgresRepository,
	mongo *repository.MongoRepository,
	cache *repository.CacheRepository,
	auth *AuthService,
) *MockSeedService {
	return &MockSeedService{
		postgres: postgres,
		mongo:    mongo,
		cache:    cache,
		auth:     auth,
	}
}

func (s *MockSeedService) Seed(ctx context.Context) error {
	driverHash, err := s.auth.HashPassword("password123")
	if err != nil {
		return err
	}
	passengerHash, err := s.auth.HashPassword("password123")
	if err != nil {
		return err
	}

	driverA, err := s.postgres.UpsertUser(ctx, domain.User{
		ID:           "driver-demo-001",
		Name:         "Naran Driver",
		Email:        "driver@example.com",
		PasswordHash: driverHash,
		Role:         "driver",
		CreatedAt:    time.Date(2026, 4, 1, 8, 0, 0, 0, time.UTC),
	})
	if err != nil {
		return err
	}
	driverB, err := s.postgres.UpsertUser(ctx, domain.User{
		ID:           "driver-demo-002",
		Name:         "Temuulen Driver",
		Email:        "driver2@example.com",
		PasswordHash: driverHash,
		Role:         "driver",
		CreatedAt:    time.Date(2026, 4, 2, 8, 0, 0, 0, time.UTC),
	})
	if err != nil {
		return err
	}
	passengerA, err := s.postgres.UpsertUser(ctx, domain.User{
		ID:           "passenger-demo-001",
		Name:         "Anu Passenger",
		Email:        "passenger@example.com",
		PasswordHash: passengerHash,
		Role:         "passenger",
		CreatedAt:    time.Date(2026, 4, 3, 8, 0, 0, 0, time.UTC),
	})
	if err != nil {
		return err
	}

	routes := []domain.SavedRoute{
		{
			ID:        "route-demo-001",
			UserID:    driverA.ID,
			From:      "Sukhbaatar Square",
			To:        "Zaisan Hill",
			Midpoints: []string{"National Amusement Park", "Central Tower"},
			CreatedAt: time.Date(2026, 4, 10, 8, 15, 0, 0, time.UTC),
		},
		{
			ID:        "route-demo-002",
			UserID:    driverA.ID,
			From:      "Dragon Center",
			To:        "Chinggis Khaan Airport",
			Midpoints: []string{"Yarmag", "Nisekh Roundabout"},
			CreatedAt: time.Date(2026, 4, 10, 9, 0, 0, 0, time.UTC),
		},
		{
			ID:        "route-demo-003",
			UserID:    driverB.ID,
			From:      "Ulaanbaatar Station",
			To:        "Shangri-La Mall",
			Midpoints: []string{"State Department Store"},
			CreatedAt: time.Date(2026, 4, 11, 7, 45, 0, 0, time.UTC),
		},
	}
	for _, route := range routes {
		if _, err := s.postgres.UpsertSavedRoute(ctx, route); err != nil {
			return err
		}
	}

	trips := []domain.Trip{
		{
			ID:          "trip-demo-001",
			PassengerID: passengerA.ID,
			DriverID:    driverA.ID,
			Route:       routes[0],
			Status:      "active",
			CreatedAt:   time.Date(2026, 4, 16, 1, 0, 0, 0, time.UTC),
			UpdatedAt:   time.Date(2026, 4, 16, 1, 5, 0, 0, time.UTC),
		},
		{
			ID:          "trip-demo-002",
			PassengerID: passengerA.ID,
			DriverID:    driverB.ID,
			Route:       routes[2],
			Status:      "completed",
			CreatedAt:   time.Date(2026, 4, 15, 4, 0, 0, 0, time.UTC),
			UpdatedAt:   time.Date(2026, 4, 15, 5, 10, 0, 0, time.UTC),
		},
	}
	for _, trip := range trips {
		if _, err := s.mongo.UpsertTrip(ctx, trip); err != nil {
			return err
		}
		if err := s.cache.CacheTripStatus(ctx, trip.ID, trip.Status, 24*time.Hour); err != nil {
			return err
		}
	}

	messages := []domain.ChatMessage{
		{
			ID:        "chat-demo-001",
			TripID:    "trip-demo-001",
			SenderID:  passengerA.ID,
			Message:   "I am waiting near the east gate.",
			CreatedAt: time.Date(2026, 4, 16, 1, 1, 0, 0, time.UTC),
		},
		{
			ID:        "chat-demo-002",
			TripID:    "trip-demo-001",
			SenderID:  driverA.ID,
			Message:   "I am 2 minutes away.",
			CreatedAt: time.Date(2026, 4, 16, 1, 2, 30, 0, time.UTC),
		},
		{
			ID:        "chat-demo-003",
			TripID:    "trip-demo-002",
			SenderID:  driverB.ID,
			Message:   "Trip completed. Thank you.",
			CreatedAt: time.Date(2026, 4, 15, 5, 8, 0, 0, time.UTC),
		},
	}
	for _, message := range messages {
		if _, err := s.mongo.UpsertChatMessage(ctx, message); err != nil {
			return err
		}
	}

	locations := []domain.DriverLocation{
		{
			DriverID:   driverA.ID,
			Latitude:   47.8864,
			Longitude:  106.9057,
			Heading:    88,
			RecordedAt: time.Now().UTC(),
		},
		{
			DriverID:   driverB.ID,
			Latitude:   47.9145,
			Longitude:  106.8748,
			Heading:    140,
			RecordedAt: time.Now().UTC(),
		},
	}
	for _, location := range locations {
		if err := s.cache.SaveDriverLocation(ctx, location, 5*time.Minute); err != nil {
			return err
		}
	}

	return nil
}

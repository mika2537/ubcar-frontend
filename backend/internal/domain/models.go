package domain

import "time"

type User struct {
	ID           string    `json:"id" bson:"id"`
	Name         string    `json:"name" bson:"name"`
	Email        string    `json:"email" bson:"email"`
	PasswordHash string    `json:"-" bson:"passwordHash"`
	Role         string    `json:"role" bson:"role"`
	CreatedAt    time.Time `json:"createdAt" bson:"createdAt"`
}

type SavedRoute struct {
	ID        string    `json:"id" bson:"id"`
	UserID    string    `json:"userId" bson:"userId"`
	From      string    `json:"from" bson:"from"`
	To        string    `json:"to" bson:"to"`
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
}

type Trip struct {
	ID          string     `json:"id" bson:"id"`
	PassengerID string     `json:"passengerId" bson:"passengerId"`
	DriverID    string     `json:"driverId,omitempty" bson:"driverId,omitempty"`
	Route       SavedRoute `json:"route" bson:"route"`
	Status      string     `json:"status" bson:"status"`
	CreatedAt   time.Time  `json:"createdAt" bson:"createdAt"`
	UpdatedAt   time.Time  `json:"updatedAt" bson:"updatedAt"`
}

type ChatMessage struct {
	ID        string    `json:"id" bson:"id"`
	TripID    string    `json:"tripId" bson:"tripId"`
	SenderID  string    `json:"senderId" bson:"senderId"`
	Message   string    `json:"message" bson:"message"`
	CreatedAt time.Time `json:"createdAt" bson:"createdAt"`
}

type DriverLocation struct {
	DriverID   string    `json:"driverId"`
	Latitude   float64   `json:"latitude"`
	Longitude  float64   `json:"longitude"`
	Heading    float64   `json:"heading"`
	RecordedAt time.Time `json:"recordedAt"`
}

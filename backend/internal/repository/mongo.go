package repository

import (
	"context"
	"time"

	"cursorubcar/backend/internal/domain"
	"github.com/google/uuid"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MongoRepository struct {
	client *mongo.Client
	db     *mongo.Database
	trips  *mongo.Collection
	chat   *mongo.Collection
}

func NewMongoRepository(uri, database string) (*MongoRepository, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, options.Client().ApplyURI(uri))
	if err != nil {
		return nil, err
	}
	if err := client.Ping(ctx, nil); err != nil {
		_ = client.Disconnect(context.Background())
		return nil, err
	}

	db := client.Database(database)
	repo := &MongoRepository{
		client: client,
		db:     db,
		trips:  db.Collection("trips"),
		chat:   db.Collection("chat_messages"),
	}
	return repo, repo.ensureIndexes(ctx)
}

func (r *MongoRepository) Close(ctx context.Context) error {
	return r.client.Disconnect(ctx)
}

func (r *MongoRepository) ensureIndexes(ctx context.Context) error {
	_, err := r.trips.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "passengerId", Value: 1}}},
		{Keys: bson.D{{Key: "driverId", Value: 1}}},
		{Keys: bson.D{{Key: "status", Value: 1}}},
	})
	if err != nil {
		return err
	}

	_, err = r.chat.Indexes().CreateMany(ctx, []mongo.IndexModel{
		{Keys: bson.D{{Key: "tripId", Value: 1}, {Key: "createdAt", Value: 1}}},
	})
	return err
}

func (r *MongoRepository) CreateTrip(ctx context.Context, trip domain.Trip) (domain.Trip, error) {
	if trip.ID == "" {
		trip.ID = uuid.NewString()
	}
	now := time.Now().UTC()
	if trip.CreatedAt.IsZero() {
		trip.CreatedAt = now
	}
	trip.UpdatedAt = now

	_, err := r.trips.InsertOne(ctx, trip)
	return trip, err
}

func (r *MongoRepository) ListTripsByUser(ctx context.Context, userID string) ([]domain.Trip, error) {
	filter := bson.M{
		"$or": []bson.M{
			{"driverId": userID},
			{"passengerId": userID},
		},
	}
	cur, err := r.trips.Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}}))
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var trips []domain.Trip
	if err := cur.All(ctx, &trips); err != nil {
		return nil, err
	}
	return trips, nil
}

func (r *MongoRepository) UpdateTripStatus(ctx context.Context, tripID, status string) (domain.Trip, error) {
	now := time.Now().UTC()
	update := bson.M{
		"$set": bson.M{
			"status":    status,
			"updatedAt": now,
		},
	}
	opts := options.FindOneAndUpdate().SetReturnDocument(options.After)

	var trip domain.Trip
	err := r.trips.FindOneAndUpdate(ctx, bson.M{"id": tripID}, update, opts).Decode(&trip)
	if err == mongo.ErrNoDocuments {
		return domain.Trip{}, ErrNotFound
	}
	return trip, err
}

func (r *MongoRepository) CreateChatMessage(ctx context.Context, message domain.ChatMessage) (domain.ChatMessage, error) {
	if message.ID == "" {
		message.ID = uuid.NewString()
	}
	if message.CreatedAt.IsZero() {
		message.CreatedAt = time.Now().UTC()
	}

	_, err := r.chat.InsertOne(ctx, message)
	return message, err
}

func (r *MongoRepository) ListChatMessages(ctx context.Context, tripID string) ([]domain.ChatMessage, error) {
	cur, err := r.chat.Find(
		ctx,
		bson.M{"tripId": tripID},
		options.Find().SetSort(bson.D{{Key: "createdAt", Value: 1}}),
	)
	if err != nil {
		return nil, err
	}
	defer cur.Close(ctx)

	var messages []domain.ChatMessage
	if err := cur.All(ctx, &messages); err != nil {
		return nil, err
	}
	return messages, nil
}

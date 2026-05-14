package repository

import (
	"context"
	"encoding/json"
	"fmt"

	"cursorubcar/backend/internal/domain"
)

func (r *CacheRepository) PublishDriverLocation(ctx context.Context, location domain.DriverLocation) error {
	payload, err := json.Marshal(location)
	if err != nil {
		return err
	}
	return r.client.Publish(ctx, driverLocationChannel(location.DriverID), payload).Err()
}

func (r *CacheRepository) StreamDriverLocation(ctx context.Context, driverID string, locations chan<- domain.DriverLocation) error {
	pubsub := r.client.Subscribe(ctx, driverLocationChannel(driverID))
	defer pubsub.Close()

	channel := pubsub.Channel()
	for {
		select {
		case msg := <-channel:
			if msg == nil {
				return nil
			}
			var location domain.DriverLocation
			if err := json.Unmarshal([]byte(msg.Payload), &location); err != nil {
				continue
			}
			select {
			case locations <- location:
			case <-ctx.Done():
				return nil
			}
		case <-ctx.Done():
			return nil
		}
	}
}

func driverLocationChannel(driverID string) string {
	return fmt.Sprintf("driver:%s:location", driverID)
}

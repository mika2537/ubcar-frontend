package api

import "time"

type ErrorResponse struct {
	Code      string    `json:"code"`
	Message   string    `json:"message"`
	Details   any       `json:"details,omitempty"`
	Timestamp time.Time `json:"timestamp"`
	RequestID string    `json:"requestId"`
}

type SuccessResponse struct {
	Data      any       `json:"data"`
	Timestamp time.Time `json:"timestamp"`
	RequestID string    `json:"requestId"`
}

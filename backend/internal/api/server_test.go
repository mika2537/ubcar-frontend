package api

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWriteJSONWrapsSuccessResponse(t *testing.T) {
	server := &Server{}
	recorder := httptest.NewRecorder()

	server.writeJSON(recorder, http.StatusCreated, map[string]string{"status": "ok"})

	if recorder.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusCreated)
	}
	if recorder.Header().Get("X-Request-ID") == "" {
		t.Fatal("missing X-Request-ID header")
	}

	var response SuccessResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.RequestID == "" || response.Timestamp.IsZero() {
		t.Fatalf("missing response metadata: %+v", response)
	}
	data, ok := response.Data.(map[string]any)
	if !ok || data["status"] != "ok" {
		t.Fatalf("data = %#v, want status ok", response.Data)
	}
}

func TestWriteErrorWrapsErrorResponse(t *testing.T) {
	server := &Server{}
	recorder := httptest.NewRecorder()

	server.writeError(recorder, http.StatusBadRequest, "bad payload")

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}

	var response ErrorResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &response); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if response.Message != "bad payload" || response.Code != http.StatusText(http.StatusBadRequest) {
		t.Fatalf("response = %+v", response)
	}
}

func TestValidator(t *testing.T) {
	validator := Validator{}

	if err := validator.ValidateEmail("test@example.com"); err != nil {
		t.Fatalf("valid email rejected: %v", err)
	}
	if err := validator.ValidateEmail("bad-email"); err == nil {
		t.Fatal("invalid email accepted")
	}
	if err := validator.ValidatePassword("Password1"); err != nil {
		t.Fatalf("valid password rejected: %v", err)
	}
	if err := validator.ValidatePassword("password1"); err == nil {
		t.Fatal("password without uppercase accepted")
	}
}

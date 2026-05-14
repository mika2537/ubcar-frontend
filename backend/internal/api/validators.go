package api

import (
	"errors"
	"fmt"
	"regexp"
	"strings"
)

type Validator struct{}

var (
	emailPattern     = regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
	uppercasePattern = regexp.MustCompile(`[A-Z]`)
	numberPattern    = regexp.MustCompile(`[0-9]`)
)

func (v Validator) ValidateEmail(email string) error {
	if !emailPattern.MatchString(strings.TrimSpace(email)) {
		return errors.New("valid email is required")
	}
	return nil
}

func (v Validator) ValidatePassword(password string) error {
	if len(password) < 8 {
		return errors.New("password must be at least 8 characters")
	}
	if !uppercasePattern.MatchString(password) {
		return errors.New("password must contain an uppercase letter")
	}
	if !numberPattern.MatchString(password) {
		return errors.New("password must contain a number")
	}
	return nil
}

func (v Validator) ValidateUserProfile(role, phoneNumber, gender string, age int, carModel, carPlate, driverLicenseID string) error {
	if role != "driver" && role != "passenger" {
		return errors.New("role must be driver or passenger")
	}

	if strings.TrimSpace(phoneNumber) == "" {
		return errors.New("phoneNumber is required")
	}

	normalizedGender := normalizeGender(gender)
	if normalizedGender != "male" && normalizedGender != "female" && normalizedGender != "other" {
		return errors.New("gender must be male, female, or other")
	}

	if age < 18 || age > 100 {
		return fmt.Errorf("age must be between %d and %d", 18, 100)
	}

	if role == "driver" {
		if strings.TrimSpace(carModel) == "" || strings.TrimSpace(carPlate) == "" || strings.TrimSpace(driverLicenseID) == "" {
			return errors.New("carModel, carPlate, and driverLicenseId are required for driver")
		}
	}

	return nil
}

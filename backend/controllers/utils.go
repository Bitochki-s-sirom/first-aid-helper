package controllers

import (
	"context"
	"encoding/json"
	"errors"
	"first_aid_companion/models"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// APIResponse represents a standard API response structure.
type APIResponse struct {
	Status int         `json:"status"`
	Data   interface{} `json:"data"`
}

// Error represents an error message returned by the API.
type Error struct {
	Message string `json:"message"`
}

// Claims represents the JWT claims structure including user information.
type Claims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// jwtKey is the secret key used to sign JWT tokens.
var jwtKey = "GOIDA"

// ParseJSON parses the JSON payload from the request body into the given destination struct.
// Returns an error if decoding fails. Ignores if ContentLength is 0.
func ParseJSON(r *http.Request, dst interface{}) error {
	if r.ContentLength == 0 {
		return nil
	}
	if err := json.NewDecoder(r.Body).Decode(dst); err != nil {
		return err
	}
	return nil
}

// WriteJSON writes the given data as a JSON response with the specified HTTP status code.
func WriteJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)

	if err := json.NewEncoder(w).Encode(data); err != nil {
		http.Error(w, "Internal server error", http.StatusInternalServerError)
	}
}

// WriteError writes an error message as a JSON response with the specified HTTP status code.
func WriteError(w http.ResponseWriter, status int, message string) {
	WriteJSON(w, status,
		&APIResponse{
			Status: status,
			Data:   Error{Message: message},
		},
	)
}

// HashPassword generates a bcrypt hash of the password for secure storage.
func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

// CheckPasswordHash compares a plaintext password with a hashed password and returns true if they match.
func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

// GenerateJWT generates a signed JWT token string for a user with a 24-hour expiry.
func GenerateJWT(userID, email string) (string, error) {
	expirationTime := time.Now().Add(24 * time.Hour)

	claims := &Claims{
		UserID: userID,
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(expirationTime),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			NotBefore: jwt.NewNumericDate(time.Now()),
			Issuer:    "first-aid-app",
			Subject:   userID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(jwtKey))
}

// ParseJWT parses and validates a JWT token string, returning the Claims if valid.
func ParseJWT(tokenStr string) (*Claims, error) {
	claims := &Claims{}
	token, err := jwt.ParseWithClaims(tokenStr, claims, func(token *jwt.Token) (interface{}, error) {
		// Provide the secret key for verification
		return []byte(jwtKey), nil
	})

	if err != nil || !token.Valid {
		return nil, fmt.Errorf("invalid token: %v", err)
	}

	return claims, nil
}

// ExtractTokenFromHeader extracts the JWT token string from the Authorization header.
// Expected header format: "Bearer <token>"
func ExtractTokenFromHeader(r *http.Request) (string, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return "", fmt.Errorf("Authorization header missing")
	}

	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", fmt.Errorf("Invalid Authorization header format")
	}

	return parts[1], nil
}

// GetUserFromContext retrieves the user ID from the request context, returning an error if not found.
func GetUserFromContext(ctx context.Context, db *gorm.DB) (int, string, error) {
	claims, ok := ctx.Value("user").(*Claims)
	if !ok || claims == nil {
		return 0, "", errors.New("no user in context")
	}

	id, err := strconv.Atoi(claims.UserID)
	if err != nil {
		log.Printf("Error parsing user ID from context: %v", err)
		return 0, "", err
	}

	var user models.User
	err = db.Table("users").Where("email = ?", claims.Email).First(&user).Error
	if err != nil {
		return 0, "", err
	}

	return id, "", nil
}

// Custom time to suit flutter format
type CustomTime time.Time

// Method for JSON unmarshaling
func (ct *CustomTime) UnmarshalJSON(b []byte) error {
	s := strings.Trim(string(b), ``)
	t, err := time.Parse("2006-01-02T15:04:05.000", s)
	if err != nil {
		return err
	}
	*ct = CustomTime(t)
	return nil
}

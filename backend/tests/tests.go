package tests

import (
	"bytes"
	"encoding/json"
	"net/http"
	"testing"
)

const baseURL = "http://localhost:8080" // Your server address

func TestSignUp(t *testing.T) {
	payload := map[string]string{
		"name":     "Test User",
		"email":    "test@example.com",
		"password": "secure123",
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(baseURL+"/signup", "application/json", bytes.NewBuffer(body))
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	// Parse response to get token
	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		t.Fatalf("Failed to decode response: %v", err)
	}
	if result["data"] == nil {
		t.Error("Expected JWT token in response")
	}
}

func TestLogin(t *testing.T) {
	payload := map[string]string{
		"email":    "test@example.com",
		"password": "secure123",
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(baseURL+"/login", "application/json", bytes.NewBuffer(body))
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}
}

func TestProtectedEndpoint(t *testing.T) {
	// First login to get token
	loginPayload := map[string]string{
		"email":    "test@example.com",
		"password": "secure123",
	}
	loginBody, _ := json.Marshal(loginPayload)

	loginResp, err := http.Post(baseURL+"/login", "application/json", bytes.NewBuffer(loginBody))
	if err != nil {
		t.Fatalf("Login failed: %v", err)
	}
	defer loginResp.Body.Close()

	var loginResult map[string]interface{}
	if err := json.NewDecoder(loginResp.Body).Decode(&loginResult); err != nil {
		t.Fatalf("Failed to decode login response: %v", err)
	}

	token, ok := loginResult["data"].(string)
	if !ok {
		t.Fatal("Token not found in login response")
	}

	// Now test protected endpoint
	req, err := http.NewRequest("GET", baseURL+"/auth/me", nil)
	if err != nil {
		t.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}
}

package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
)

type APIResponse struct {
	Status int         `json:"status"`
	Data   interface{} `json:"data"`
}

const (
	baseURL      = "http://localhost:8080"
	testEmail    = "testuser4@example.com" // Single email for all tests
	testPassword = "secure123"
	testName     = "Test User"
)

// Helper functions
// Updated getAuthToken function
// getAuthToken retrieves a JWT token
func getAuthToken() string {
	loginPayload := map[string]string{
		"email":    testEmail,
		"password": testPassword,
	}
	body, _ := json.Marshal(loginPayload)

	resp, err := http.Post(baseURL+"/login", "application/json", bytes.NewBuffer(body))
	if err != nil {
		log.Fatalf("Login failed: %v", err)
	}
	defer resp.Body.Close()

	var result APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Fatalf("Failed to decode login response: %v", err)
	}

	if token, ok := result.Data.(string); ok {
		return token
	}

	log.Fatal("Token not found in response")
	return ""
}

// Updated cleanupTestUser function to handle
// Tests
func TestSignUp() {

	payload := map[string]string{
		"name":     testName,
		"email":    testEmail,
		"password": testPassword,
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(baseURL+"/signup", "application/json", bytes.NewBuffer(body))
	if err != nil {
		log.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Fatalf("Expected status 200, got %d", resp.StatusCode)
	}

	var result map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Fatalf("Failed to decode response: %v", err)
	}
	if result["data"] == nil {
		log.Fatal("Expected JWT token in response")
	}
}

func TestLogin() {
	token := getAuthToken()
	if token == "" {
		log.Fatal("Failed to get auth token")
	}
}

func TestUpdateUserInfo() {
	token := getAuthToken()

	updatePayload := map[string]string{
		"passport": "1234567890",
		"snils":    "123-456-789 00",
		"address":  "123 Test Street",
	}
	body, _ := json.Marshal(updatePayload)

	req, err := http.NewRequest("POST", baseURL+"/auth/me", bytes.NewBuffer(body))
	if err != nil {
		log.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Fatalf("Expected status 200, got %d", resp.StatusCode)
	}

	// Verify updates
	req, err = http.NewRequest("GET", baseURL+"/auth/me", nil)
	if err != nil {
		log.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err = client.Do(req)
	if err != nil {
		log.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	var userData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&userData); err != nil {
		log.Fatalf("Failed to decode user data: %v", err)
	}

	if userData["passport"] != updatePayload["passport"] ||
		userData["snils"] != updatePayload["snils"] ||
		userData["address"] != updatePayload["address"] {
		log.Fatal("User data not updated correctly")
	}
}

func TestUpdateMedicalCard() {
	token := getAuthToken()

	updatePayload := map[string]string{
		"allergies":    "Peanuts, Shellfish",
		"chronic_cond": "Asthma",
		"blood_type":   "A+",
	}
	body, _ := json.Marshal(updatePayload)

	req, err := http.NewRequest("POST", baseURL+"/auth/me", bytes.NewBuffer(body))
	if err != nil {
		log.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Fatalf("Expected status 200, got %d", resp.StatusCode)
	}

	// Verify updates
	req, err = http.NewRequest("GET", baseURL+"/auth/me", nil)
	if err != nil {
		log.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err = client.Do(req)
	if err != nil {
		log.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	var userData map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&userData); err != nil {
		log.Fatalf("Failed to decode user data: %v", err)
	}

	if userData["allergies"] != updatePayload["allergies"] ||
		userData["chronic_conditions"] != updatePayload["chronic_cond"] ||
		userData["blood_type"] != updatePayload["blood_type"] {
		log.Fatal("Medical card not updated correctly")
	}
}

func TestPartialUpdates() {
	token := getAuthToken()

	updatePayload := map[string]string{
		"blood_type": "B+",
	}
	body, _ := json.Marshal(updatePayload)

	req, err := http.NewRequest("POST", baseURL+"/auth/me", bytes.NewBuffer(body))
	if err != nil {
		log.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Fatalf("Expected status 200, got %d", resp.StatusCode)
	}
}

func TestProtectedEndpoint() {
	token := getAuthToken()

	req, err := http.NewRequest("GET", baseURL+"/auth/me", nil)
	if err != nil {
		log.Fatalf("Failed to create request: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		log.Fatalf("Request failed: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Fatalf("Expected status 200, got %d", resp.StatusCode)
	}
}

var createdChatID uint

func TestCreateChat() {
	token := getAuthToken()

	req, err := http.NewRequest("POST", baseURL+"/auth/new_chat", nil)
	if err != nil {
		log.Fatalf("CreateChat request failed: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatalf("CreateChat HTTP error: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		log.Fatalf("CreateChat failed: %s", string(body))
	}

	var result APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Fatalf("CreateChat decode error: %v", err)
	}

	idFloat, ok := result.Data.(float64)
	if !ok {
		log.Fatal("CreateChat response ID not valid")
	}
	createdChatID = uint(idFloat)
	log.Println("✅ Created chat with ID:", createdChatID)
}

func TestGetUserChats() {
	token := getAuthToken()

	req, err := http.NewRequest("GET", baseURL+"/auth/chats", nil)
	if err != nil {
		log.Fatalf("GetUserChats request error: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatalf("GetUserChats HTTP error: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		log.Fatalf("GetUserChats failed: %s", string(body))
	}

	var result APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Fatalf("GetUserChats decode error: %v", err)
	}

	log.Println("📋 User Chats:", result.Data)
}

func TestGetChatByID() {
	token := getAuthToken()

	url := fmt.Sprintf("%s/auth/chats/%d", baseURL, createdChatID)
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		log.Fatalf("GetChatByID request error: %v", err)
	}
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatalf("GetChatByID HTTP error: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		body, _ := io.ReadAll(resp.Body)
		log.Fatalf("GetChatByID failed: %s", string(body))
	}

	var result APIResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		log.Fatalf("GetChatByID decode error: %v", err)
	}

	log.Println("📨 Chat Messages:", result.Data)
}

func main() {
	// Run tests in logical order
	TestSignUp()
	TestLogin()
	TestProtectedEndpoint()
	TestUpdateUserInfo()
	TestUpdateMedicalCard()
	TestPartialUpdates()
	TestCreateChat()
	TestGetUserChats()
	TestGetChatByID()

	log.Println("🎉 All tests passed.")
}

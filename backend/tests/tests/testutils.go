package tests

import (
	"bytes"
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

type TestConfig struct {
	BaseURL      string `json:"base_url"`
	TestEmail    string `json:"test_email"`
	TestPassword string `json:"test_password"`
	TestName     string `json:"test_name"`
}

var config TestConfig

func init() {
	loadTestConfig()
}

func loadTestConfig() {
	configFile, err := os.Open("../testdata/test_config.json")
	if err != nil {
		log.Fatalf("Error opening test config: %v", err)
	}
	defer configFile.Close()

	byteValue, _ := io.ReadAll(configFile)
	if err := json.Unmarshal(byteValue, &config); err != nil {
		log.Fatalf("Error parsing test config: %v", err)
	}
}

func getAuthToken(t *testing.T) string {
	loginPayload := map[string]string{
		"email":    config.TestEmail,
		"password": config.TestPassword,
	}
	body, _ := json.Marshal(loginPayload)

	resp, err := http.Post(config.BaseURL+"/login", "application/json", bytes.NewBuffer(body))
	require.NoError(t, err)
	defer resp.Body.Close()

	require.Equal(t, http.StatusOK, resp.StatusCode)

	var result struct {
		Status int    `json:"status"`
		Data   string `json:"data"`
	}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(t, err)

	return result.Data
}

func cleanupTestUser(t *testing.T) {
	token := getAuthToken(t)
	req, _ := http.NewRequest("DELETE", config.BaseURL+"/auth/me", nil)
	req.Header.Set("Authorization", "Bearer "+token)

	client := &http.Client{}
	resp, err := client.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Logf("Cleanup warning: Failed to delete test user: %d", resp.StatusCode)
	}
}

func requireOK(t *testing.T, resp *http.Response) {
	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		t.Fatalf("Expected status 200, got %d: %s", resp.StatusCode, string(body))
	}
}

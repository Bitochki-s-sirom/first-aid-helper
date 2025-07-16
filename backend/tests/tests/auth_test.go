package tests

import (
	"bytes"
	"encoding/json"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type AuthTestSuite struct {
	suite.Suite
	token string
}

func (suite *AuthTestSuite) Test1_SignUp() {
	payload := map[string]string{
		"name":     config.TestName,
		"email":    config.TestEmail,
		"password": config.TestPassword,
	}
	body, _ := json.Marshal(payload)

	resp, err := http.Post(config.BaseURL+"/signup", "application/json", bytes.NewBuffer(body))
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	var result map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(suite.T(), err)
	assert.NotNil(suite.T(), result["data"])
}

func (suite *AuthTestSuite) Test2_Login() {
	suite.token = getAuthToken(suite.T())
	assert.NotEmpty(suite.T(), suite.token)
}

func (suite *AuthTestSuite) Test3_ProtectedEndpoint() {
	req, err := http.NewRequest("GET", config.BaseURL+"/auth/me", nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	client := &http.Client{}
	resp, err := client.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)
}

func (suite *AuthTestSuite) Test4_UpdateUserInfo() {
	updatePayload := map[string]string{
		"passport": "1234567890",
		"snils":    "123-456-789 00",
		"address":  "123 Test Street",
	}
	body, _ := json.Marshal(updatePayload)

	req, err := http.NewRequest("POST", config.BaseURL+"/auth/me", bytes.NewBuffer(body))
	require.NoError(suite.T(), err)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+suite.token)

	client := &http.Client{}
	resp, err := client.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	// Verify updates
	req, err = http.NewRequest("GET", config.BaseURL+"/auth/me", nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err = client.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	var userData map[string]interface{}
	require.NoError(suite.T(), json.NewDecoder(resp.Body).Decode(&userData))

	assert.Equal(suite.T(), updatePayload["passport"], userData["passport"])
	assert.Equal(suite.T(), updatePayload["snils"], userData["snils"])
	assert.Equal(suite.T(), updatePayload["address"], userData["address"])
}

func TestAuthSuite(t *testing.T) {
	suite.Run(t, new(AuthTestSuite))
}

package tests

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"first_aid_companion/controllers"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type Document struct {
	ID       uint      `json:"id"`
	UserID   uint      `json:"user_id"`
	Name     string    `json:"name"`
	Type     string    `json:"type"`
	Date     time.Time `json:"date"`
	Doctor   string    `json:"doctor"`
	FileData []byte    `json:"file_data"`
}

type DocumentTestSuite struct {
	suite.Suite
	token  string
	sample map[string]interface{}
}

func (suite *DocumentTestSuite) SetupSuite() {
	suite.token = getAuthToken(suite.T())

	// prepare a sample document payload
	now := time.Now().UTC().Format(time.RFC3339)
	down := []byte("sample file content")
	suite.sample = map[string]interface{}{
		"name":      "Test Report",
		"type":      "report",
		"date":      now,
		"doctor":    "Dr. Test",
		"file_data": base64.StdEncoding.EncodeToString(down),
	}
}

func (suite *DocumentTestSuite) Test1_AddDocument() {
	bodyBytes, err := json.Marshal(suite.sample)
	require.NoError(suite.T(), err)

	req, err := http.NewRequest("POST", config.BaseURL+"/auth/documents/add", bytes.NewBuffer(bodyBytes))
	require.NoError(suite.T(), err)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	require.Equal(suite.T(), http.StatusOK, resp.StatusCode)
}

func (suite *DocumentTestSuite) Test2_GetDocuments() {
	req, err := http.NewRequest("GET", config.BaseURL+"/auth/documents", nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	require.Equal(suite.T(), http.StatusOK, resp.StatusCode)

	// Decode response into APIResponse
	var response controllers.APIResponse
	err = json.NewDecoder(resp.Body).Decode(&response)
	require.NoError(suite.T(), err)

	// Convert response.Data to JSON, then into []Document
	dataBytes, err := json.Marshal(response.Data)
	require.NoError(suite.T(), err)

	var docs []Document
	err = json.Unmarshal(dataBytes, &docs)
	require.NoError(suite.T(), err)

	assert.Greater(suite.T(), len(docs), 0, "Expected at least one document")

	// Verify the sample document exists by matching the name field
	found := false
	for _, doc := range docs {
		if doc.Name == suite.sample["name"].(string) {
			found = true
			break
		}
	}
	assert.True(suite.T(), found, fmt.Sprintf("Document %q not found in response", suite.sample["name"]))
}

func TestDocumentSuite(t *testing.T) {
	suite.Run(t, new(DocumentTestSuite))
}

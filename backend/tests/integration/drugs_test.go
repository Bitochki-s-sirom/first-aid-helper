package integration

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type DrugsTestSuite struct {
	suite.Suite
	token  string
	drugID int
}

func (suite *DrugsTestSuite) SetupSuite() {
	suite.token = getAuthToken(suite.T())
}

func (suite *DrugsTestSuite) Test1_AddDrug() {
	payload := map[string]interface{}{
		"name":         "Ibuprofen",
		"type":         "Painkiller",
		"description":  "Used to reduce fever and treat pain or inflammation",
		"expiry":       "2026-01-01T00:00:00Z",
		"location":     "Home Medicine Cabinet",
		"manufacturer": "Pfizer",
		"dose":         "200mg",
		"amount":       "30 tablets",
	}
	body, _ := json.Marshal(payload)

	req, err := http.NewRequest("POST", config.BaseURL+"/auth/drugs/add", bytes.NewBuffer(body))
	require.NoError(suite.T(), err)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)
}

func (suite *DrugsTestSuite) Test2_ListDrugs() {
	req, err := http.NewRequest("GET", config.BaseURL+"/auth/drugs", nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	var result struct {
		Status int                      `json:"status"`
		Data   []map[string]interface{} `json:"data"`
	}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(suite.T(), err)

	require.Greater(suite.T(), len(result.Data), 0)
	lastDrug := result.Data[len(result.Data)-1]
	suite.drugID = int(lastDrug["id"].(float64))
}

func (suite *DrugsTestSuite) Test3_RemoveDrug() {
	url := fmt.Sprintf("%s/auth/drugs/remove/%d", config.BaseURL, suite.drugID)
	req, err := http.NewRequest("POST", url, nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)
}

func (suite *DrugsTestSuite) Test4_VerifyDrugRemoved() {
	req, _ := http.NewRequest("GET", config.BaseURL+"/auth/drugs", nil)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	var result struct {
		Status int                      `json:"status"`
		Data   []map[string]interface{} `json:"data"`
	}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(suite.T(), err)

	for _, drug := range result.Data {
		if int(drug["id"].(float64)) == suite.drugID {
			suite.T().Fatalf("Drug ID %d still exists", suite.drugID)
		}
	}
}

func TestDrugsSuite(t *testing.T) {
	suite.Run(t, new(DrugsTestSuite))
}

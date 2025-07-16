package tests

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/stretchr/testify/suite"
)

type ChatTestSuite struct {
	suite.Suite
	token  string
	chatID uint
}

func (suite *ChatTestSuite) SetupSuite() {
	suite.token = getAuthToken(suite.T())
}

func (suite *ChatTestSuite) Test1_CreateChat() {
	req, err := http.NewRequest("POST", config.BaseURL+"/auth/new_chat", nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	var result struct {
		Status int     `json:"status"`
		Data   float64 `json:"data"`
	}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(suite.T(), err)

	suite.chatID = uint(result.Data)
	assert.NotZero(suite.T(), suite.chatID)
}

func (suite *ChatTestSuite) Test2_GetUserChats() {
	req, err := http.NewRequest("GET", config.BaseURL+"/auth/chats", nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	var result struct {
		Status int         `json:"status"`
		Data   interface{} `json:"data"`
	}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(suite.T(), err)

	chats, ok := result.Data.([]interface{})
	require.True(suite.T(), ok)
	assert.Greater(suite.T(), len(chats), 0)
}

func (suite *ChatTestSuite) Test3_GetChatByID() {
	url := fmt.Sprintf("%s/auth/chats/%d", config.BaseURL, suite.chatID)
	req, err := http.NewRequest("GET", url, nil)
	require.NoError(suite.T(), err)
	req.Header.Set("Authorization", "Bearer "+suite.token)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	var result struct {
		Status int         `json:"status"`
		Data   interface{} `json:"data"`
	}
	err = json.NewDecoder(resp.Body).Decode(&result)
	require.NoError(suite.T(), err)
}

func (suite *ChatTestSuite) Test4_SendMessage() {
	payload := map[string]interface{}{
		"chat_id": suite.chatID,
		"text":    "How are you today?",
	}
	body, _ := json.Marshal(payload)

	req, err := http.NewRequest("POST", config.BaseURL+"/auth/send_message", bytes.NewBuffer(body))
	require.NoError(suite.T(), err)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+suite.token)

	client := &http.Client{}
	resp, err := client.Do(req)
	require.NoError(suite.T(), err)
	defer resp.Body.Close()

	requireOK(suite.T(), resp)

	// Parse SSE stream
	reader := bufio.NewReader(resp.Body)
	var aiReply strings.Builder
	for {
		line, err := reader.ReadString('\n')
		if err == io.EOF {
			break
		}
		require.NoError(suite.T(), err)

		line = strings.TrimRight(line, "\r\n")
		if line == "" {
			continue
		}
		if strings.HasPrefix(line, "event:") && strings.TrimSpace(line) == "event: done" {
			break
		}
		if strings.HasPrefix(line, "data: ") {
			aiReply.WriteString(line[6:])
		}
	}

	assert.Greater(suite.T(), aiReply.Len(), 0, "Expected non-empty AI reply")
}

func TestChatSuite(t *testing.T) {
	suite.Run(t, new(ChatTestSuite))
}

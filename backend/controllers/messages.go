package controllers

import (
	"context"
	"encoding/json"
	"first_aid_companion/models"
	"fmt"
	"log"
	"net/http"
	"strings"

	"google.golang.org/genai"
)

// ChatMessage represents a single message content in a chat.
type ChatMessage struct {
	Content string `json:"content"`
}

// MessageRequest represents the incoming request payload for sending a new message.
type MessageRequest struct {
	ChatID  uint   `json:"chat_id"` // ID of the chat session
	Message string `json:"text"`    // Text content of the message sent by user
}

// MessageService handles message-related operations, including persistence and AI responses.
type MessageService struct {
	ApiKey string              // API key for connecting to the AI service
	DB     *models.MessageGorm // Database interface for message storage
}

// NewMessage handles the submission of a user's chat message and streams an AI response.
// @Summary Send a message and receive AI response via SSE
// @Description Stores the user's message, streams a response from the AI model, and stores the AI reply.
// @Tags chats
// @Accept json
// @Produce text/event-stream
// @Param input body MessageRequest true "Chat ID and user message"
// @Success 200 {string} string "streamed AI response"
// @Failure 400 {object} APIResponse "Invalid request body or empty message"
// @Failure 500 {object} APIResponse "Internal server or streaming error"
// @Router /auth/send_message [post]
// @Security BearerAuth
func (ms *MessageService) NewMessage(w http.ResponseWriter, r *http.Request) {
	var request MessageRequest

	// Decode incoming JSON request into MessageRequest struct
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid JSON format")
		return
	}

	// Validate that the message text is not empty or just whitespace
	if strings.TrimSpace(request.Message) == "" {
		WriteError(w, http.StatusBadRequest, "message cannot be empty")
		return
	}

	// Save the user's message in the database (role 0 = user)
	if _, err := ms.DB.AddMessage(request.ChatID, 0, request.Message); err != nil {
		log.Printf("DB save error: %v", err)
		WriteError(w, http.StatusInternalServerError, "failed to save message")
		return
	}

	// Set HTTP headers for Server-Sent Events (SSE)
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	// Ensure the ResponseWriter supports flushing to send partial data
	flusher, ok := w.(http.Flusher)
	if !ok {
		WriteError(w, http.StatusInternalServerError, "streaming unsupported")
		return
	}

	// Create a context for API client
	ctx := context.Background()

	// Initialize the GenAI client with API key and backend choice
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  ms.ApiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to initialize LLM client")
		log.Fatal(err)
		return
	}

	// Start streaming generation of AI response for the user's message
	stream := client.Models.GenerateContentStream(
		ctx,
		"gemini-1.5-flash",          // AI model to use
		genai.Text(request.Message), // Input prompt from user message
		nil,                         // Optional generation params
	)

	aiResponse := ""

	// Read streamed chunks of generated content from the AI
	for chunk, _ := range stream {
		// Extract text part from the chunk
		part := chunk.Candidates[0].Content.Parts[0]
		// Accumulate partial response
		aiResponse += part.Text

		// Write partial text as an SSE data event to client
		fmt.Fprintf(w, "data: %s\n\n", strings.ReplaceAll(part.Text, "\n", "\\n"))
		flusher.Flush() // Flush response to client immediately
	}

	// Send a custom SSE event to indicate streaming is complete
	fmt.Fprintf(w, "event: done\ndata: completed\n\n")
	flusher.Flush()

	// Save the complete AI-generated response in the database (role 1 = AI)
	if _, err := ms.DB.AddMessage(request.ChatID, 1, aiResponse); err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to save LLM response")
		log.Fatal(err)
		return
	}

	log.Println("Successfully generated the response!")
}

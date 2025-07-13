package controllers

import (
	"context"
	"encoding/json"
	"first_aid_companion/models"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/joho/godotenv"
	"google.golang.org/genai"
)

type ChatMessage struct {
	Role    string `json:"role"` // "user" or "model"
	Content string `json:"content"`
}

type MessageRequest struct {
	ChatID   uint          `json:"chat_id"`
	Message  string        `json:"text"`
	Messages []ChatMessage `json:"messages"` // Optional: full chat history
}

type MessageService struct {
	DB          *models.MessageGorm
	UserService *UserService
}

const (
	LLMUserID = 0 // System user ID for LLM responses
	modelName = "models/gemini-pro"
)

func (ms *MessageService) NewMessage(w http.ResponseWriter, r *http.Request) {
	err := godotenv.Load()
	if err != nil {
		log.Fatalf("Error loading .env file")
	}

	user, err := ms.UserService.GetUserFromContext(r.Context())
	if err != nil || user == nil {
		WriteError(w, http.StatusUnauthorized, "session expired or invalid")
		return
	}

	var request MessageRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid JSON format")
		return
	}
	if strings.TrimSpace(request.Message) == "" {
		WriteError(w, http.StatusBadRequest, "message cannot be empty")
		return
	}

	if _, err := ms.DB.AddMessage(request.ChatID, user.ID, request.Message); err != nil {
		log.Printf("DB save error: %v", err)
		WriteError(w, http.StatusInternalServerError, "failed to save message")
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	flusher, ok := w.(http.Flusher)
	if !ok {
		WriteError(w, http.StatusInternalServerError, "streaming unsupported")
		return
	}

	apiKey := os.Getenv("GEMINI_API_KEY")

	ctx := context.Background()
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  apiKey,
		Backend: genai.BackendGeminiAPI,
	})
	if err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to initialize LLM client")
		log.Fatal(err)
		return
	}

	stream := client.Models.GenerateContentStream(
		ctx,
		"gemini-1.5-flash",
		genai.Text(request.Message),
		nil,
	)

	for chunk, _ := range stream {
		part := chunk.Candidates[0].Content.Parts[0]
		fmt.Fprintf(w, "data: %s\n\n", part)
		flusher.Flush()
	}

	fmt.Fprintf(w, "event: done\ndata: [stream closed]\n\n")
	flusher.Flush()

	log.Panicln("Successfully generated the response!")
}

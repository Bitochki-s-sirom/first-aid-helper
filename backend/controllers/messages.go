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

type ChatMessage struct {
	Content string `json:"content"`
}

type MessageRequest struct {
	ChatID  uint   `json:"chat_id"`
	Message string `json:"text"`
}

type MessageService struct {
	ApiKey string
	DB     *models.MessageGorm
}

func (ms *MessageService) NewMessage(w http.ResponseWriter, r *http.Request) {
	var request MessageRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		WriteError(w, http.StatusBadRequest, "invalid JSON format")
		return
	}
	if strings.TrimSpace(request.Message) == "" {
		WriteError(w, http.StatusBadRequest, "message cannot be empty")
		return
	}

	if _, err := ms.DB.AddMessage(request.ChatID, 0, request.Message); err != nil {
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

	ctx := context.Background()
	client, err := genai.NewClient(ctx, &genai.ClientConfig{
		APIKey:  ms.ApiKey,
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

	aiResponse := ""
	for chunk, _ := range stream {
		part := chunk.Candidates[0].Content.Parts[0]
		aiResponse += part.Text
		fmt.Fprintf(w, "data: %s\n\n", part.Text)
		flusher.Flush()
	}

	fmt.Fprintf(w, "event: done\ndata: [stream closed]\n\n")
	flusher.Flush()

	if _, err := ms.DB.AddMessage(request.ChatID, 1, aiResponse); err != nil {
		WriteError(w, http.StatusInternalServerError, "failed to save LLM response")
		log.Fatal(err)
		return
	}

	log.Println("Successfully generated the response!")
}

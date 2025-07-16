package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

// ChatService manages chat-related operations, interacting with the database layer.
type ChatService struct {
	DB *models.ChatGorm // Database handler for chat data
}

// NewChat creates a new chat session for the authenticated user.
// @Summary Create a new chat
// @Description Creates a new chat with a temporary title for the current user and returns the chat ID.
// @Tags chats
// @Produce json
// @Success 200 {object} APIResponse "Data: chatID"
// @Failure 500 {object} APIResponse "Server or database error"
// @Router /auth/chats [post]
// @Security BearerAuth
func (cs *ChatService) NewChat(w http.ResponseWriter, r *http.Request) {
	// Extract user ID from the request context (populated by authentication middleware)
	userID, _, err := GetUserFromContext(r.Context(), cs.DB.DB)
	if err != nil {
		log.Printf("Error getting user in NewChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Create a new chat record with the user ID and a placeholder title
	chat, err := cs.DB.CreateChat(uint(userID), "Temp title")
	if err != nil {
		log.Printf("Error creating new chat in NewChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Respond with the newly created chat's ID in JSON format
	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   chat.ID,
	})

	log.Println("Successfully created new chat!")
}

// GetUsersChats retrieves all chat sessions for the authenticated user.
// @Summary Get user's chat sessions
// @Description Returns a list of chat IDs and titles associated with the current user.
// @Tags chats
// @Produce json
// @Success 200 {object} APIResponse "[ {title: string, id: caht_id}, ...]"
// @Failure 500 {object} APIResponse "Failed to fetch user's chats"
// @Router /auth/chats [get]
// @Security BearerAuth
func (cs *ChatService) GetUsersChats(w http.ResponseWriter, r *http.Request) {
	// Get authenticated user ID from context
	userID, _, err := GetUserFromContext(r.Context(), cs.DB.DB)
	if err != nil {
		log.Printf("Error getting user in NewChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Retrieve chats belonging to the user
	chats, err := cs.DB.GetUserChats(uint(userID))
	if err != nil {
		log.Printf("Error updating user data in GetUsersChats: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Prepare a response array of maps with chat title and ID for each chat
	var response []map[string]interface{}
	for _, chat := range chats {
		response = append(response, map[string]interface{}{
			"title": chat.Title,
			"id":    chat.ID,
		})
	}

	// Send the response with HTTP 200 status
	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   &response,
	})
}

// GetChat retrieves all messages from a specific chat.
// @Summary Get messages from a chat
// @Description Returns the list of messages in a given chat, including message ID, sender, and text.
// @Tags chats
// @Produce json
// @Param id path int true "Chat ID"
// @Success 200 {object} APIResponse "[ {id: message_id, sender: 0/1, text: message_text}, ...]"
// @Failure 500 {object} APIResponse "Failed to fetch chat or messages"
// @Router /auth/chats/{id} [get]
// @Security BearerAuth
func (cs *ChatService) GetChat(w http.ResponseWriter, r *http.Request) {
	// Extract the chat ID from URL variables using mux
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		log.Printf("Error getting chat in GetChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Retrieve the chat and its associated messages from the database by chat ID
	chat, err := cs.DB.GetChatByID(uint(id))
	if err != nil {
		log.Printf("Error getting chat in GetChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Prepare response slice containing maps of message details
	var response []map[string]interface{}
	for _, message := range chat.Messages {
		response = append(response, map[string]interface{}{
			"id":     message.ID,
			"sender": message.Sender,
			"text":   message.Text,
		})
	}

	// Return the list of messages as JSON with HTTP 200 status
	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   &response,
	})
}

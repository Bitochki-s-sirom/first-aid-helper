package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

type ChatService struct {
	DB *models.ChatGorm
}

func (cs *ChatService) NewChat(w http.ResponseWriter, r *http.Request) {
	userID, err := GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error getting user in NewChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	chat, err := cs.DB.CreateChat(uint(userID), "Temp title")
	if err != nil {
		log.Printf("Error creating new chat in NewChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   chat.ID,
	})

	log.Println("Successfully created new chat!")
}

func (cs *ChatService) GetUsersChats(w http.ResponseWriter, r *http.Request) {
	userID, err := GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error getting user in NewChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	chats, err := cs.DB.GetUserChats(uint(userID))
	if err != nil {
		log.Printf("Error updating user data in GetUsersChats: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	var response []map[string]interface{}
	for _, chat := range chats {
		response = append(response, map[string]interface{}{
			"title": chat.Title,
			"id":    chat.ID,
		})
	}

	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   &response,
	})
}

func (cs *ChatService) GetChat(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		log.Printf("Error getting chat in GetChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	chat, err := cs.DB.GetChatByID(uint(id))
	if err != nil {
		log.Printf("Error getting chat in GetChat: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	var response []map[string]interface{}
	for _, message := range chat.Messages {
		response = append(response, map[string]interface{}{
			"id":     message.ID,
			"sender": message.Sender,
			"text":   message.Text,
		})
	}

	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   &response,
	})
}

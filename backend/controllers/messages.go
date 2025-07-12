package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
)

type MessageRequest struct {
	ChatID  uint   `json:"chat_id"`
	Message string `json:"text"`
}

type MessageService struct {
	DB          *models.MessageGorm
	UserService *UserService
}

func (ms *MessageService) NewMessage(w http.ResponseWriter, r *http.Request) {
	var request MessageRequest
	if err := ParseJSON(r, &request); err != nil {
		log.Printf("Error adding message in NewMessage: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	_, err := ms.DB.AddMessage(request.ChatID, 1, request.Message)
	if err != nil {
		log.Printf("Error adding message in NewMessage: %v", err)
		WriteError(w, 500, err.Error())
		return
	}
}

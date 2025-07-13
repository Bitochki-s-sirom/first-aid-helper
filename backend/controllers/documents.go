package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
)

type DocumentService struct {
	DB          *models.DocumentGorm
	UserService *UserService
}

// @Summary Get all documents
// @Description Returns all user documents in json format
// @Tags documents
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.Document
// @Router /auth/documents [get]
func (ds *DocumentService) Documents(w http.ResponseWriter, r *http.Request) {
	user, err := ds.UserService.GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}
	docs, err := ds.DB.GetDocumentsByUserId(user.ID)
	if err != nil {
		log.Printf("Error fetching documents: %v", err)
		WriteError(w, 500, "database error")
		return
	}
	WriteJSON(w, 200, docs)
}

// @Summary Add one document
// @Tags documents
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body models.Document true "document body"
// @Success 200 {array} APIResponse
// @Router /auth/documents/add [post]
func (ds *DocumentService) AddDocument(w http.ResponseWriter, r *http.Request) {
	newDoc := &models.Document{}
	if err := ParseJSON(r, newDoc); err != nil {
		log.Printf("Error parsing JSON in AddDocument: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	user, err := ds.UserService.GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	newDoc.UserID = user.ID

	_, err = ds.DB.CreateDocument(newDoc)
	if err != nil {
		log.Printf("Error creating document in AddDocument: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, nil)
}

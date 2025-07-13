package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

// Represents request1's JSON
type DocumentUploadRequest struct {
	Name     string    `json:"name"`                                // Name/title of the document
	Type     string    `json:"type"`                                // Type/category of document (e.g. prescription, report)
	Date     time.Time `json:"date" example:"2025-07-12T23:45:00Z"` // Date the document was created or issued
	Doctor   string    `json:"doctor"`                              // Name of the doctor associated with the document
	FileData []byte    `json:"file_data"`                           // File contents (binary), base64-encoded when serialized to JSON
}

// DocumentService handles operations related to user's documents, interfacing with the database.
type DocumentService struct {
	DB *models.DocumentGorm
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
	// Get user id from request context
	userID, err := GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	// Get user's documents
	docs, err := ds.DB.GetDocumentsByUserId(uint(userID))
	if err != nil {
		log.Printf("Error fetching documents: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   &docs,
	})
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
	docUploadRequest := &DocumentUploadRequest{}
	// Get document description from JSON
	if err := ParseJSON(r, docUploadRequest); err != nil {
		log.Printf("Error parsing JSON in AddDocument: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Get user from request context
	userID, err := GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	// New document record for db
	newDoc := &models.Document{
		UserID:   uint(userID),
		Name:     docUploadRequest.Name,
		Doctor:   docUploadRequest.Doctor,
		Type:     docUploadRequest.Type,
		Date:     docUploadRequest.Date,
		FileData: docUploadRequest.FileData,
	}

	// Create a record in DB
	_, err = ds.DB.CreateDocument(newDoc)
	if err != nil {
		log.Printf("Error creating document in AddDocument: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, nil)
	log.Println("Successfully added a new document!")
}

// @Summary Remove one document by id
// @Tags documents
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} APIResponse
// @Router /auth/document/remove/{id} [post]
func (ds *DocumentService) RemoveDocument(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		log.Printf("Error removing document in RemoveDocument: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	if err := ds.DB.DeleteDocumentById(id); err != nil {
		log.Printf("Error removing document in RemoveDocument: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	log.Println("Successfully removed document!")
}

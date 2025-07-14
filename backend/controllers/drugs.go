package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
)

// Represents request for drug creation
// It includes various fields describing the medication and its metadata.
type DrugCreationRequest struct {
	Name         string    `json:"name"`                                  // Name of the drug
	Type         string    `json:"type"`                                  // Type or category of the drug
	Description  string    `json:"description"`                           // Description or purpose of the drug
	Expiry       time.Time `json:"expiry" example:"2025-07-12T23:45:00Z"` // Expiry date of the drug
	Location     string    `json:"location"`                              // Storage location of the drug
	Manufacturer string    `json:"manufacturer"`                          // Manufacturer of the drug
	Dose         string    `json:"dose"`                                  // Dosage information
	Amount       string    `json:"amount"`                                // Quantity of the drug available
}

// DrugService handles operations related to drugs, interfacing with the database.
type DrugService struct {
	DB *models.DrugGorm // Database access object for drugs
}

// @Summary Get all drugs
// @Description Returns all drugs in json format
// @Tags drugs
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {array} models.Drug
// @Router /auth/drugs [get]
func (ds *DrugService) Drugs(w http.ResponseWriter, r *http.Request) {
	// Fetch user from request context
	// User must be present due to AuthMiddleware
	userID, _, err := GetUserFromContext(r.Context(), ds.DB.DB)
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	// Collect all user's drugs
	drugs, err := ds.DB.GetDrugsByUserId(uint(userID))
	if err != nil {
		log.Printf("Error fetching drugs: %v", err)
		WriteError(w, 500, "database error")
		return
	}
	WriteJSON(w, 200, &APIResponse{Status: 200, Data: drugs})
}

// @Summary Add one drug
// @Tags drugs
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body DrugCreationRequest true "login body"
// @Success 200 {array} APIResponse
// @Router /auth/drugs/add [post]
func (ds *DrugService) AddDrug(w http.ResponseWriter, r *http.Request) {
	request := &DrugCreationRequest{}
	// Get drug description form JSON
	if err := ParseJSON(r, request); err != nil {
		log.Printf("Error parsing JSON in AddDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Get user id form request context
	userID, _, err := GetUserFromContext(r.Context(), ds.DB.DB)
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	// Create a drug
	drug := &models.Drug{
		Name:         request.Name,
		Type:         request.Type,
		Description:  request.Description,
		Expiry:       request.Expiry,
		Location:     request.Location,
		Manufacturer: request.Manufacturer,
		Dose:         request.Dose,
		Amount:       request.Amount,
	}

	// Cast int to unit
	drug.UserId = uint(userID)

	// Create a record in DB
	_, err = ds.DB.CreateDrug(drug)
	if err != nil {
		log.Printf("Error creating drug in AddDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, nil)
	log.Println("Successfully added a new drug!")
}

// @Summary Remove one drug by id
// @Tags drugs
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body DrugCreationRequest true "login body"
// @Success 200 {object} APIResponse
// @Router /auth/drugs/remove/{id} [post]
func (ds *DrugService) RemoveDrug(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id, err := strconv.Atoi(vars["id"])
	if err != nil {
		log.Printf("Error removing drug in RemoveDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	if err := ds.DB.DeleteDrugById(id); err != nil {
		log.Printf("Error removing drug in RemoveDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	log.Println("Successfully removed drug!")
}

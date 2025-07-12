package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
	"time"
)

type DrugCreation struct {
	Name        string    `json:"name"`
	Type        string    `json:"type"`
	Description string    `json:"description"`
	Expiry      time.Time `json:"expiry" example:"2025-07-12T23:45:00Z"`
	Location    string    `json:"location"`
}

type DrugService struct {
	DB          *models.DrugGorm
	UserService *UserService
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
	user, err := ds.UserService.GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}
	drugs, err := ds.DB.GetDrugsByUserId(user.ID)
	if err != nil {
		log.Printf("Error fetching drugs: %v", err)
		WriteError(w, 500, "database error")
		return
	}
	WriteJSON(w, 200, drugs)
}

// @Summary Add one drug
// @Tags drugs
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body DrugCreation true "login body"
// @Success 200 {array} APIResponse
// @Router /auth/drugs/add [post]
func (ds *DrugService) AddDrug(w http.ResponseWriter, r *http.Request) {
	newDrug := &DrugCreation{}
	if err := ParseJSON(r, newDrug); err != nil {
		log.Printf("Error parsing JSON in AddDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	user, err := ds.UserService.GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	userId := user.ID

	_, err = ds.DB.CreateDrug(newDrug.Name, newDrug.Type, newDrug.Description, newDrug.Location, newDrug.Expiry, userId)
	if err != nil {
		log.Printf("Error creating drug in AddDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, nil)
}

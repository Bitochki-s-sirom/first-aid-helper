package controllers

import (
	"first_aid_companion/models"
	"log"
	"net/http"
)

type DrugService struct {
	DB *models.DrugGorm
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
	userID, err := GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}
	drugs, err := ds.DB.GetDrugsByUserId(uint(userID))
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
// @Param input body models.Drug true "login body"
// @Success 200 {array} APIResponse
// @Router /auth/drugs/add [post]
func (ds *DrugService) AddDrug(w http.ResponseWriter, r *http.Request) {
	drug := &models.Drug{}
	if err := ParseJSON(r, drug); err != nil {
		log.Printf("Error parsing JSON in AddDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	userID, err := GetUserFromContext(r.Context())
	if err != nil {
		log.Printf("Error fetching user: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	// drug := &Drug{
	// 	Name:        new,
	// 	Type:        newDrug.Type,
	// 	Description: newDrug.Description,
	// 	Expiry:      newDrug.Expiry,
	// 	Location:    newDrug.Location,
	// 	UserId:      user.ID,
	// }

	drug.UserId = uint(userID)

	_, err = ds.DB.CreateDrug(drug)
	if err != nil {
		log.Printf("Error creating drug in AddDrug: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, nil)
}

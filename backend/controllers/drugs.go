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
	drugs, err := ds.DB.GetAllDrugs()
	if err != nil {
		log.Printf("Error fetching drugs: %v", err)
		WriteError(w, 500, "database error")
		return
	}
	WriteJSON(w, 200, drugs)
}

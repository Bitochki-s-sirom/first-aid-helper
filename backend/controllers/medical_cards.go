package controllers

import "first_aid_companion/models"

// MedicalCardService provides methods to manage medical cards,
// interacting with the underlying database layer.
type MedicalCardService struct {
	DB *models.MedicalCardGorm // Database access object for medical cards
}

// CreateCard creates a new medical card for a given user with empty default fields.
// It calls the DB layer to persist the card and returns the created card or an error.
func (ms *MedicalCardService) CreateCard(userID uint) (*models.MedicalCard, error) {
	// Initializes with empty fields
	return ms.DB.CreateCard("", "", "", userID)
}

// GetCard fetches the medical card associated with the specified user ID.
// Returns the medical card if found, or an error otherwise.
func (ms *MedicalCardService) GetCard(userID uint) (*models.MedicalCard, error) {
	return ms.DB.GetCardByUserID(userID)
}

// UpdateCard updates an existing medical card record in the database.
// Takes a pointer to the medical card object to update and returns an error if update fails.
func (ms *MedicalCardService) UpdateCard(medCard *models.MedicalCard) error {
	return ms.DB.UpdateCard(medCard)
}

package models

import (
	"time"

	"gorm.io/gorm"
)

// Drug represents a medication record stored by a user.
// It includes various fields describing the medication and its metadata.
type Drug struct {
	ID           uint      `gorm:"primaryKey" json:"id"`                  // Unique identifier for the drug (hidden from JSON)
	UserId       uint      `json:"user_id"`                               // ID of the user who owns the drug (hidden from JSON)
	Name         string    `json:"name"`                                  // Name of the drug
	Type         string    `json:"type"`                                  // Type or category of the drug
	Description  string    `json:"description"`                           // Description or purpose of the drug
	Expiry       time.Time `json:"expiry" example:"2025-07-12T23:45:00Z"` // Expiry date of the drug
	Location     string    `json:"location"`                              // Storage location of the drug
	Manufacturer string    `json:"manufacturer"`                          // Manufacturer of the drug
	Dose         string    `json:"dose"`                                  // Dosage information
	Amount       string    `json:"amount"`                                // Quantity of the drug available
}

// DrugGorm wraps a GORM DB instance for performing database operations on the Drug model.
type DrugGorm struct {
	DB *gorm.DB
}

// NewDrugGorm creates a new instance of DrugGorm.
func NewDrugGorm(db *gorm.DB) *DrugGorm {
	return &DrugGorm{DB: db}
}

// CreateDrug inserts a new drug record into the database.
// Takes a pointer to a Drug struct and returns the created record or an error.
func (dg *DrugGorm) CreateDrug(drug *Drug) (*Drug, error) {
	if err := dg.DB.Table("drugs").Create(drug).Error; err != nil {
		return nil, err
	}
	return drug, nil
}

// GetDrugById retrieves a drug record by its ID.
// Returns the drug or an error if not found.
func (dg *DrugGorm) GetDrugById(id int) (*Drug, error) {
	var drug Drug
	if err := dg.DB.Table("drugs").Where("id = ?", id).First(&drug).Error; err != nil {
		return nil, err
	}
	return &drug, nil
}

// UpdateDrug updates an existing drug record with the provided fields.
// Accepts a map of fields to update and returns the updated drug or an error.
func (dg *DrugGorm) UpdateDrug(id int, args map[string]interface{}) (*Drug, error) {
	drug, err := dg.GetDrugById(id)
	if err != nil {
		return nil, err
	}

	// Update fields if provided
	if val, ok := args["Type"].(string); ok {
		drug.Type = val
	}
	if val, ok := args["Description"].(string); ok {
		drug.Description = val
	}
	if val, ok := args["Expiry"].(time.Time); ok {
		drug.Expiry = val
	}
	if val, ok := args["Location"].(string); ok {
		drug.Location = val
	}

	// Save the updated record
	if err := dg.DB.Table("drugs").Save(drug).Error; err != nil {
		return nil, err
	}
	return drug, nil
}

// GetDrugsByUserId retrieves all drug records associated with a specific user ID.
// Returns a slice of drugs or an error.
func (dg *DrugGorm) GetDrugsByUserId(id uint) ([]Drug, error) {
	var drugs []Drug
	err := dg.DB.Table("drugs").Where("user_id = ?", id).Find(&drugs).Error
	if err != nil {
		return nil, err
	}
	return drugs, nil
}

// DeleteDrugById deletes a drug record from the database by its ID.
// Returns an error if the operation fails.
func (dg *DrugGorm) DeleteDrugById(id int) error {
	if err := dg.DB.Table("drugs").Where("id = ?", id).Delete(&Drug{}).Error; err != nil {
		return err
	}
	return nil
}

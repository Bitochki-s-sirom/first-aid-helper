package models

import "gorm.io/gorm"

// MedicalCard represents a user's health record with basic medical information.
type MedicalCard struct {
	ID          uint   `gorm:"primaryKey"` // Unique identifier for the medical card
	UserID      uint   // Foreign key to associate the card with a specific user
	Allergies   string // Any known allergies the user has
	ChronicCond string // Description of chronic conditions (e.g., asthma, diabetes)
	BloodType   string // Blood type (1+, 1-, 2+, 2-, ...)
}

// MedicalCardGorm provides methods to interact with the medical_cards table.
type MedicalCardGorm struct {
	DB *gorm.DB // GORM DB instance for executing queries
}

// NewMedCardGorm returns a new MedicalCardGorm instance.
func NewMedCardGorm(db *gorm.DB) *MedicalCardGorm {
	return &MedicalCardGorm{DB: db}
}

// CreateCard creates and saves a new MedicalCard record in the database.
func (mg *MedicalCardGorm) CreateCard(allergies, chronicCond, bloodType string, userID uint) (*MedicalCard, error) {
	card := &MedicalCard{
		UserID:      userID,
		Allergies:   allergies,
		ChronicCond: chronicCond,
		BloodType:   bloodType,
	}

	// Insert the new medical card record into the medical_cards table.
	if err := mg.DB.Table("medical_cards").Create(card).Error; err != nil {
		return nil, err
	}

	return card, nil
}

// GetCardByUserID fetches a medical card associated with a specific user ID.
func (mg *MedicalCardGorm) GetCardByUserID(id uint) (*MedicalCard, error) {
	card := &MedicalCard{}

	// Find the first card that matches the user_id.
	if err := mg.DB.Table("medical_cards").Where("user_id = ?", id).First(card).Error; err != nil {
		return nil, err
	}

	return card, nil
}

// UpdateCard updates the fields of an existing medical card in the
func (mg *MedicalCardGorm) UpdateCard(card *MedicalCard) error {
	return mg.DB.Table("medical_cards").Save(card).Error
}

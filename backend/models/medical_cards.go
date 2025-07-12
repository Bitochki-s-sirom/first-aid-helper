package models

import "gorm.io/gorm"

type MedicalCard struct {
	ID          uint `gorm:"primaryKey"`
	UserID      uint
	Allergies   string
	ChronicCond string
	BloodType   string
}

type MedicalCardGorm struct {
	DB *gorm.DB
}

func NewMedCardGorm(db *gorm.DB) *MedicalCardGorm {
	return &MedicalCardGorm{DB: db}
}

func (mg *MedicalCardGorm) CreateCard(allergies, chronicCond, bloodType string, userID uint) (*MedicalCard, error) {
	card := &MedicalCard{
		UserID:      userID,
		Allergies:   allergies,
		ChronicCond: chronicCond,
		BloodType:   bloodType,
	}

	if err := mg.DB.Table("medical_cards").Create(card).Error; err != nil {
		return nil, err
	}

	return card, nil
}

func (mg *MedicalCardGorm) GetCardByUserID(id uint) (*MedicalCard, error) {
	card := &MedicalCard{}

	if err := mg.DB.Table("medical_cards").Where("user_id = ?", id).First(card).Error; err != nil {
		return nil, err
	}

	return card, nil
}

func (mg *MedicalCardGorm) UpdateCard(card *MedicalCard) error {
	return mg.DB.Table("medical_cards").Save(card).Error
}

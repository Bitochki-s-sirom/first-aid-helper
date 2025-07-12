package models

type MedicalCard struct {
	ID          uint `gorm:"primaryKey"`
	UserID      uint
	Allergies   string
	ChronicCond string
	BloodType   string
}

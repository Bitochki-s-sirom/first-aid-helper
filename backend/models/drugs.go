package models

import (
	"time"

	"gorm.io/gorm"
)

type Drug struct {
	ID           uint      `gorm:"primaryKey" json:"-"`
	UserId       uint      `json:"-"`
	Name         string    `json:"name"`
	Type         string    `json:"type"`
	Description  string    `json:"description"`
	Expiry       time.Time `json:"expiry" example:"2025-07-12T23:45:00Z"`
	Location     string    `json:"location"`
	Manufacturer string    `json:"manufacturer"`
	Dose         string    `json:"dose"`
	Amount       string    `json:"amount"`
}

type DrugGorm struct {
	DB *gorm.DB
}

func NewDrugGorm(db *gorm.DB) *DrugGorm {
	return &DrugGorm{DB: db}
}

func (dg *DrugGorm) CreateDrug(drug *Drug) (*Drug, error) {

	// drug := &Drug{
	// 	Name:        name,
	// 	Type:        drugType,
	// 	Description: desc,
	// 	Expiry:      exp,
	// 	Location:    loc,
	// 	UserId:      userId,
	// }

	if err := dg.DB.Table("drugs").Create(drug).Error; err != nil {
		return nil, err
	}
	return drug, nil

}

func (dg *DrugGorm) GetDrugById(id int) (*Drug, error) {
	var drug Drug
	if err := dg.DB.Table("drugs").Where("id = ?", id).First(&drug).Error; err != nil {
		return nil, err
	}
	return &drug, nil
}

func (dg *DrugGorm) UpdateDrug(id int, args map[string]interface{}) (*Drug, error) {
	drug, err := dg.GetDrugById(id)
	if err != nil {
		return nil, err
	}

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

	if err := dg.DB.Table("drugs").Save(drug).Error; err != nil {
		return nil, err
	}
	return drug, nil
}

func (dg *DrugGorm) GetDrugsByUserId(id uint) ([]Drug, error) {
	var drugs []Drug
	err := dg.DB.Table("drugs").Where("user_id = ?", id).Find(&drugs).Error
	if err != nil {
		return nil, err
	}
	return drugs, nil
}

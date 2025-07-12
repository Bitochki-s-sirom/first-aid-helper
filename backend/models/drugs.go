package models

import (
	"time"

	"gorm.io/gorm"
)

type Drug struct {
	ID          uint `gorm:"primaryKey"`
	Type        string
	Description string
	Expiry      time.Time
	Location    string
}

type DrugGorm struct {
	DB *gorm.DB
}

func (dg *DrugGorm) CreateDrug(args map[string]interface{}) (*Drug, error) {

	drug := &Drug{}

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

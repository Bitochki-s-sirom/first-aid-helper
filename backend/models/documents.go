package models

import (
	"time"

	"gorm.io/gorm"
)

type Document struct {
	ID       uint      `gorm:"primaryKey" json:"-"`
	UserID   uint      `json:"-"`
	Name     string    `json:"name"`
	Type     string    `json:"type"`
	Date     time.Time `json:"date" example:"2025-07-12T23:45:00Z"`
	Doctor   string    `json:"doctor"`
	FileData []byte    `json:"file_data"` // base64-encoded in JSON
}

type DocumentGorm struct {
	DB *gorm.DB
}

func NewDocumentGorm(db *gorm.DB) *DocumentGorm {
	return &DocumentGorm{DB: db}
}

func (dg *DocumentGorm) CreateDocument(doc *Document) (*Document, error) {
	if err := dg.DB.Table("documents").Create(doc).Error; err != nil {
		return nil, err
	}
	return doc, nil
}

func (dg *DocumentGorm) GetDocumentById(id int) (*Document, error) {
	var doc Document
	if err := dg.DB.Table("documents").Where("id = ?", id).First(&doc).Error; err != nil {
		return nil, err
	}
	return &doc, nil
}

func (dg *DocumentGorm) GetDocumentsByUserId(userId uint) ([]Document, error) {
	var docs []Document
	err := dg.DB.Table("documents").Where("user_id = ?", userId).Find(&docs).Error
	if err != nil {
		return nil, err
	}
	return docs, nil
}

func (dg *DocumentGorm) UpdateDocument(id int, args map[string]interface{}) (*Document, error) {
	doc, err := dg.GetDocumentById(id)
	if err != nil {
		return nil, err
	}
	if val, ok := args["Name"].(string); ok {
		doc.Name = val
	}
	if val, ok := args["Type"].(string); ok {
		doc.Type = val
	}
	if val, ok := args["Date"].(time.Time); ok {
		doc.Date = val
	}
	if val, ok := args["Doctor"].(string); ok {
		doc.Doctor = val
	}
	// Optional: update file data if provided
	if val, ok := args["FileData"].([]byte); ok {
		doc.FileData = val
	}
	if err := dg.DB.Table("documents").Save(doc).Error; err != nil {
		return nil, err
	}
	return doc, nil
}

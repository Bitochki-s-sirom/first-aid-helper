package models

import (
	"time"

	"gorm.io/gorm"
)

type Document struct {
	ID       uint `gorm:"primaryKey"`
	UserID   uint
	Name     string
	Type     string
	Date     time.Time
	Doctor   string
	FileData []byte
}

type DocumentGorm struct {
	DB *gorm.DB
}

func NewDocumentGorm(db *gorm.DB) *DocumentGorm {
	return &DocumentGorm{DB: db}
}

func (dg *DocumentGorm) CreateDocument(name, docType, doctor string, date time.Time, fileData []byte, userId uint) (*Document, error) {
	doc := &Document{
		Name:     name,
		Type:     docType,
		Date:     date,
		Doctor:   doctor,
		FileData: fileData,
		UserID:   userId,
	}
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

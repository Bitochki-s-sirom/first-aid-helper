package models

import (
	"time"

	"gorm.io/gorm"
)

// Document represents a medical document record belonging to a user.
type Document struct {
	ID       uint      `gorm:"primaryKey" json:"id"`                // Unique document ID (hidden from JSON)
	UserID   uint      `json:"user_id"`                             // ID of the user the document belongs to (hidden from JSON)
	Name     string    `json:"name"`                                // Name/title of the document
	Type     string    `json:"type"`                                // Type/category of document (e.g. prescription, report)
	Date     time.Time `json:"date" example:"2025-07-12T23:45:00Z"` // Date the document was created or issued
	Doctor   string    `json:"doctor"`                              // Name of the doctor associated with the document
	FileData []byte    `json:"file_data"`                           // File contents (binary), base64-encoded when serialized to JSON
}

// DocumentGorm wraps a GORM DB instance to perform CRUD operations on Document models.
type DocumentGorm struct {
	DB *gorm.DB
}

// NewDocumentGorm creates a new instance of DocumentGorm.
func NewDocumentGorm(db *gorm.DB) *DocumentGorm {
	return &DocumentGorm{DB: db}
}

// CreateDocument inserts a new document record into the database.
// Takes a pointer to a Document object and returns the created record or an error.
func (dg *DocumentGorm) CreateDocument(doc *Document) (*Document, error) {
	if err := dg.DB.Table("documents").Create(doc).Error; err != nil {
		return nil, err
	}
	return doc, nil
}

// GetDocumentById retrieves a single document by its ID.
// Returns the document or an error if not found.
func (dg *DocumentGorm) GetDocumentById(id int) (*Document, error) {
	var doc Document
	if err := dg.DB.Table("documents").Where("id = ?", id).First(&doc).Error; err != nil {
		return nil, err
	}
	return &doc, nil
}

// GetDocumentsByUserId fetches all documents belonging to a specific user by their user ID.
// Returns a slice of Document objects or an error.
func (dg *DocumentGorm) GetDocumentsByUserId(userId uint) ([]Document, error) {
	var docs []Document
	err := dg.DB.Table("documents").Where("user_id = ?", userId).Find(&docs).Error
	if err != nil {
		return nil, err
	}
	return docs, nil
}

// UpdateDocument updates fields in a document by its ID based on provided arguments in a map.
// Only provided fields are updated. Returns the updated document or an error.
func (dg *DocumentGorm) UpdateDocument(id int, args map[string]interface{}) (*Document, error) {
	doc, err := dg.GetDocumentById(id)
	if err != nil {
		return nil, err
	}

	// Conditionally update fields if present in the input map
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
	if val, ok := args["FileData"].([]byte); ok {
		doc.FileData = val
	}

	// Save updated record
	if err := dg.DB.Table("documents").Save(doc).Error; err != nil {
		return nil, err
	}
	return doc, nil
}

func (dg *DocumentGorm) DeleteDocumentById(id int) error {
	if err := dg.DB.Table("documents").Where("id = ?", id).Delete(&Document{}).Error; err != nil {
		return err
	}
	return nil
}

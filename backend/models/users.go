package models

import (
	"gorm.io/gorm"
)

// User represents a user in the system with personal and relational data.
type User struct {
	ID           uint        `gorm:"primaryKey"` // Primary key for the user
	Name         string      // Full name of the user
	Email        string      // Email address (should be unique)
	PasswordHash string      // Hashed password for secure authentication
	SNILS        string      // Russian personal insurance number
	Passport     string      // Passport number
	Address      string      // User's address
	Groups       []Group     `gorm:"many2many:user_groups;"`                         // Many-to-many relation with groups
	MedicalCard  MedicalCard `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL;"` // One-to-one relation with MedicalCard
	Documents    []Document  // One-to-many relation with documents
}

// UserGorm is the GORM wrapper for user-related database operations.
type UserGorm struct {
	DB *gorm.DB // GORM database instance
}

// NewUserGorm returns a new UserGorm instance.
func NewUserGorm(db *gorm.DB) *UserGorm {
	return &UserGorm{DB: db}
}

// CreateUser inserts a new user record into the database.
func (ug *UserGorm) CreateUser(name, email, password_hash string) (*User, error) {
	user := &User{
		Name:         name,
		Email:        email,
		PasswordHash: password_hash,
	}

	if err := ug.DB.Table("users").Create(user).Error; err != nil {
		return nil, err
	}
	return user, nil
}

// GetUserByID fetches a user from the database by their ID.
func (ug *UserGorm) GetUserByID(id int) (*User, error) {
	var user User
	if err := ug.DB.Table("users").Where("id = ?", id).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

// GetUserByEmail fetches a user by their email (used for login/auth).
func (ug *UserGorm) GetUserByEmail(email string) (*User, error) {
	var user User
	if err := ug.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

// UpdateUser updates the user's information in the database.
func (ug *UserGorm) UpdateUser(user *User) error {
	return ug.DB.Table("users").Save(user).Error
}

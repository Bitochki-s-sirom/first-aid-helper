package models

import (
	"gorm.io/gorm"
)

type User struct {
	ID           uint `gorm:"primaryKey"`
	Name         string
	Email        string
	PasswordHash string
	Groups       []Group `gorm:"many2many:user_groups;"`
	MedicalCard  MedicalCard
	Chats        []Chat
	Documents    []Document
}

type UserGorm struct {
	DB *gorm.DB
}

func NewUserGorm(db *gorm.DB) *UserGorm {
	return &UserGorm{DB: db}
}

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

func (ug *UserGorm) GetUserByID(id int) (*User, error) {
	var user User
	if err := ug.DB.Table("users").Where("id = ?", id).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

func (ug *UserGorm) GetUserByEmail(email string) (*User, error) {
	var user User
	if err := ug.DB.Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

package models

import "gorm.io/gorm"

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

func (ug *UserGorm) GetUser(id int) (*User, error) {
	var user User
	if err := ug.DB.Table("users").Where("id = ?", id).Scan(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}

package models

import (
	_ "gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Chat struct {
	ID       uint `gorm:"primaryKey"`
	UserID   uint
	Messages []Message `gorm:"one2many:messagess;"`
}

type ChatGorm struct {
	db *gorm.DB
}

func (cg *ChatGorm) CreateChat(userID int) error {
	chat := &Chat{
		UserID: uint(userID),
	}
	return cg.db.Create(chat).Error
}

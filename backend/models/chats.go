package models

import (
	_ "gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type Chat struct {
	ID       uint `gorm:"primaryKey"`
	UserID   uint
	Title    string
	Messages []Message `gorm:"one2many:messagess;"`
}

type ChatGorm struct {
	db *gorm.DB
}

func (cg *ChatGorm) CreateChat(userID int, title string) error {
	chat := &Chat{
		UserID: uint(userID),
		Title:  title,
	}
	return cg.db.Table("chats").Create(chat).Error
}

func (cg *ChatGorm) GetChat(chatID int) (*Chat, error) {
	var chat Chat
	if err := cg.db.Table("chats").Where("id = ?", chatID).Scan(&chat).Error; err != nil {
		return nil, err
	}
	return &chat, nil
}

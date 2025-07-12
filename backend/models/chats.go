package models

import (
	"gorm.io/gorm"
)

type Chat struct {
	ID       uint `gorm:"primaryKey"`
	UserID   uint
	Title    string
	Messages []Message `gorm:"foreignKey:ChatID"`
}

type ChatGorm struct {
	db *gorm.DB
}

func NewChatGorm(db *gorm.DB) *ChatGorm {
	return &ChatGorm{db: db}
}

func (cg *ChatGorm) CreateChat(userID uint, title string) (*Chat, error) {
	chat := &Chat{
		UserID: userID,
		Title:  title,
	}
	err := cg.db.Create(chat).Error
	return chat, err
}

func (cg *ChatGorm) GetChatByID(chatID uint) (*Chat, error) {
	var chat Chat
	err := cg.db.Preload("Messages").First(&chat, chatID).Error
	return &chat, err
}

func (cg *ChatGorm) GetUserChats(userID uint) ([]Chat, error) {
	var chats []Chat
	err := cg.db.Where("user_id = ?", userID).Find(&chats).Error
	return chats, err
}

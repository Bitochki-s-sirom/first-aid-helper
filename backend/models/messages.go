package models

import "gorm.io/gorm"

type Message struct {
	ID        uint `gorm:"primaryKey"`
	ChatID    uint `gorm:"index"`
	Sender    uint `gorm:"index"`
	Text      string
	Timestamp int64 `gorm:"autoCreateTime"`
}

type MessageGorm struct {
	db *gorm.DB
}

func NewMessageGorm(db *gorm.DB) *MessageGorm {
	return &MessageGorm{db: db}
}

func (mg *MessageGorm) AddMessage(chatID, sender uint, text string) (*Message, error) {
	message := &Message{
		ChatID: chatID,
		Sender: sender,
		Text:   text,
	}
	err := mg.db.Create(message).Error
	return message, err
}

func (mg *MessageGorm) GetMessages(chatID uint) ([]Message, error) {
	var messages []Message
	err := mg.db.Where("chat_id = ?", chatID).Order("timestamp asc").Find(&messages).Error
	return messages, err
}

func (mg *MessageGorm) UpdateMessage(messageID uint, newText string) error {
	return mg.db.Model(&Message{}).Where("id = ?", messageID).Update("text", newText).Error
}

func (mg *MessageGorm) DeleteMessage(messageID uint) error {
	return mg.db.Delete(&Message{}, messageID).Error
}

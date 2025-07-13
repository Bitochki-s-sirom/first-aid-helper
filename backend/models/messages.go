package models

import "gorm.io/gorm"

// Message represents a single chat message between users or with the assistant.
type Message struct {
	ID        uint   `gorm:"primaryKey"` // Unique identifier for the message
	ChatID    uint   `gorm:"index"`      // Foreign key linking the message to a chat
	Sender    uint   `gorm:"index"`      // 0 = user, 1 = assistant/AI (or custom logic)
	Text      string // Content of the message
	Timestamp int64  `gorm:"autoCreateTime"` // Automatically set when the message is created
}

// MessageGorm handles database operations related to Message using GORM.
type MessageGorm struct {
	db *gorm.DB // Database connection instance
}

// NewMessageGorm initializes a new MessageGorm service.
func NewMessageGorm(db *gorm.DB) *MessageGorm {
	return &MessageGorm{db: db}
}

// AddMessage creates a new message record in the database.
func (mg *MessageGorm) AddMessage(chatID, sender uint, text string) (*Message, error) {
	message := &Message{
		ChatID: chatID,
		Sender: sender,
		Text:   text,
	}
	err := mg.db.Create(message).Error // Inserts the message into the DB
	return message, err
}

// GetMessages retrieves all messages for a given chat ID, ordered by timestamp (oldest to newest).
func (mg *MessageGorm) GetMessages(chatID uint) ([]Message, error) {
	var messages []Message
	err := mg.db.
		Where("chat_id = ?", chatID).
		Order("timestamp asc").
		Find(&messages).Error
	return messages, err
}

// UpdateMessage updates the text of an existing message by its ID.
func (mg *MessageGorm) UpdateMessage(messageID uint, newText string) error {
	return mg.db.
		Model(&Message{}).
		Where("id = ?", messageID).
		Update("text", newText).
		Error
}

// DeleteMessage removes a message from the database using its ID.
func (mg *MessageGorm) DeleteMessage(messageID uint) error {
	return mg.db.Delete(&Message{}, messageID).Error
}

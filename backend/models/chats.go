package models

import (
	"gorm.io/gorm"
)

// Chat represents a conversation thread associated with a user.
// It contains a title and a list of messages in the conversation.
type Chat struct {
	ID       uint      `gorm:"primaryKey"` // Unique identifier for the chat
	UserID   uint      // ID of the user who owns the chat
	Title    string    // Title of the chat (e.g., "Doctor Consultation")
	Messages []Message `gorm:"foreignKey:ChatID"` // Messages associated with this chat
}

// ChatGorm is a wrapper around GORM's DB object to encapsulate chat-related DB operations.
type ChatGorm struct {
	DB *gorm.DB
}

// NewChatGorm initializes a new ChatGorm instance.
func NewChatGorm(db *gorm.DB) *ChatGorm {
	return &ChatGorm{DB: db}
}

// CreateChat creates a new chat with a given user ID and title.
// Returns the created chat or an error.
func (cg *ChatGorm) CreateChat(userID uint, title string) (*Chat, error) {
	chat := &Chat{
		UserID: userID,
		Title:  title,
	}
	err := cg.DB.Create(chat).Error
	return chat, err
}

// GetChatByID retrieves a chat by its ID along with all its associated messages.
// Uses GORM's Preload to load the related Messages slice.
func (cg *ChatGorm) GetChatByID(chatID uint) (*Chat, error) {
	var chat Chat
	err := cg.DB.Preload("Messages").First(&chat, chatID).Error
	return &chat, err
}

// GetUserChats retrieves all chats that belong to a given user by their user ID.
// Returns a slice of Chat objects or an error.
func (cg *ChatGorm) GetUserChats(userID uint) ([]Chat, error) {
	var chats []Chat
	err := cg.DB.Where("user_id = ?", userID).Find(&chats).Error
	return chats, err
}

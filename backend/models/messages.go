package models

type Message struct {
	ID     uint `gorm:"primaryKey"`
	ChatID uint
	Sender uint
	Text   string
}

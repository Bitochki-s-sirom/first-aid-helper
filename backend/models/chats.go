package models

type Chat struct {
	ID       uint `gorm:"primaryKey"`
	UserID   uint
	Messages []Message `gorm:"one2many:messagess;"`
}

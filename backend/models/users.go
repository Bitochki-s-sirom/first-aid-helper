package models

type User struct {
	ID          uint `gorm:"primaryKey"`
	Name        string
	Surname     string
	Groups      []Group `gorm:"many2many:user_groups;"`
	MedicalCard MedicalCard
	Chats       []Chat
	Documents   []Document
}

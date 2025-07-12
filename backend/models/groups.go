package models

type Group struct {
	ID          uint `gorm:"primaryKey"`
	Name        string
	Description string
	Members     []User `gorm:"many2many:user_groups;"`
}

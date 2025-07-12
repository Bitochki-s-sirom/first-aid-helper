package models

import "time"

type Document struct {
	ID          uint `gorm:"primaryKey"`
	UserID      uint
	Name        string
	Type        string
	Date        time.Time
	PathToPhoto string
	Doctor      string
}

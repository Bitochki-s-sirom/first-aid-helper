package models

import "time"

type Drug struct {
	ID          uint `gorm:"primaryKey"`
	Type        string
	Description string
	Expiry      time.Time
	Location    string
}

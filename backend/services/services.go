package services

import (
	"first_aid_companion/models"
	"fmt"

	_ "gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type DBService struct {
	DB     *gorm.DB
	UserDB *models.UserGorm
}

func NewDBService(db *gorm.DB) *DBService {
	return &DBService{
		DB:     db,
		UserDB: models.NewUserGorm(db),
	}
}

func (db *DBService) Automigrate() error {
	err := db.DB.AutoMigrate(
		&models.User{},
		&models.Chat{},
		&models.Message{},
		&models.Document{},
		&models.Group{},
		&models.Drug{},
		&models.MedicalCard{},
	)

	if err != nil {
		fmt.Printf("Error during automigration: %v", err)
		return err
	}

	return nil
}

package services

import (
	"first_aid_companion/models"
	"fmt"
	"log"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type DBService struct {
	DB        *gorm.DB
	UserDB    *models.UserGorm
	DrugDB    *models.DrugGorm
	MedCardDB *models.MedicalCardGorm
	ChatDB    *models.ChatGorm
	DocsDB    *models.DocumentGorm
	MessageDB *models.MessageGorm
	ApiKey    string
}

func NewDBService(ApiKey, dsn string) (*DBService, error) {
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
		return nil, err
	}
	log.Println("Successfully connected to database")

	return &DBService{
		DB:        db,
		UserDB:    models.NewUserGorm(db),
		DrugDB:    models.NewDrugGorm(db),
		MedCardDB: models.NewMedCardGorm(db),
		ChatDB:    models.NewChatGorm(db),
		MessageDB: models.NewMessageGorm(db),
		ApiKey:    ApiKey,
	}, nil
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

func (db *DBService) ResetDB() error {
	err := db.DB.Migrator().DropTable(
		&models.User{},
		&models.Chat{},
		&models.Message{},
		&models.Document{},
		&models.Group{},
		&models.Drug{},
		&models.MedicalCard{},
	)
	if err != nil {
		return fmt.Errorf("failed to drop tables: %w", err)
	}

	return db.Automigrate()
}

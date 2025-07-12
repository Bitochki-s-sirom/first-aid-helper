package main

import (
	"first_aid_companion/handlers"
	"first_aid_companion/services"
	"log"
	"net/http"

	"github.com/gorilla/mux"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	dsn := `host=localhost user=postgres password=1121 dbname=firstaid port=5432 sslmode=disable`
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		panic(err)
	}

	dbService := services.NewDBService(db)
	if err := dbService.Automigrate(); err != nil {
		return
	}

	router := mux.NewRouter()
	handlers.AddRoutes(router, dbService)

	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	log.Fatal(srv.ListenAndServe())
}

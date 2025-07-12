package main

import (
	"first_aid_companion/handlers"
	"first_aid_companion/services"
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

func main() {
	router := mux.NewRouter()
	handlers.AddRoutes(router)

	dsn := `host=82.202.138.91 user=postgres password=h,RVN/G&iK£kkB75s>C"%Q9}1F;nNz dbname=firstaid port=5432 sslmode=disable`
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{Logger: nil})
	if err != nil {
		panic(err)
	}

	dbService := services.NewDBService(db)
	if err := dbService.Automigrate(); err != nil {
		return
	}

	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	if err := srv.ListenAndServe(); err != nil {
		fmt.Println("Server failed to start: %v", err)
	}
}

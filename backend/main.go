package main

import (
	"first_aid_companion/handlers"
	"first_aid_companion/services"
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
)

func main() {
	// Initialize logger with timestamp and file info
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// // Load env variables with API key for GemiAI and dsn for postgres
	// err := godotenv.Load()
	// if err != nil {
	// 	log.Fatalf("Error loading .env file")
	// }

	// Get variables
	apiKey := os.Getenv("GEMINI_API_KEY")
	dsn := "host=postgres  user=postgres password=your_secure_password dbname=firstaid port=5432 sslmode=disable"

	// Initialize DB service
	dbService, _ := services.NewDBService(apiKey, dsn)

	// Automigrate DB
	if err := dbService.Automigrate(); err != nil {
		log.Fatalf("Failed to automigrate database: %v", err)
	}
	log.Println("Database automigration completed successfully")

	// Rest DB
	if err := dbService.ResetDB(); err != nil {
		log.Fatalf("Failed to reset database: %v", err)
	}
	log.Println("Database reset completed successfully")

	// Set up router
	router := mux.NewRouter()

	// Apply logging middleware
	router.Use(handlers.LoggingMiddleware)

	// Add routes
	handlers.AddRoutes(router, dbService)
	log.Println("Routes configured successfully")

	// Add CORS Middleware
	handler := handlers.CorsMiddleware.Handler(router)

	// Configure and start server
	srv := &http.Server{
		Addr:    ":8080",
		Handler: handler,
	}

	log.Println("Starting server on :8080")
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

// @securityDefinitions.apikey BearerAuth
// @in header
// @name Authorization

package main

import (
	"first_aid_companion/handlers"
	"first_aid_companion/services"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// LoggingMiddleware logs details of each HTTP request and response
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Record start time
		start := time.Now()

		// Create a response writer wrapper to capture status code
		lrw := &loggingResponseWriter{w, http.StatusOK}

		// Call the next handler
		next.ServeHTTP(lrw, r)

		// Log request details
		log.Printf(
			"Request: %s %s, Status: %d, Duration: %v, RemoteAddr: %s",
			r.Method,
			r.RequestURI,
			lrw.statusCode,
			time.Since(start),
			r.RemoteAddr,
		)
	})
}

// loggingResponseWriter wraps http.ResponseWriter to capture status code
type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

// WriteHeader captures the status code
func (lrw *loggingResponseWriter) WriteHeader(code int) {
	lrw.statusCode = code
	lrw.ResponseWriter.WriteHeader(code)
}

func main() {
	// Initialize logger with timestamp and file info
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Database connection
	dsn := `host= 82.202.138.91 user=postgres password=h,RVN/G&iK£kkB75s>C"%Q9}1F;nNz dbname=firstaid port=5432 sslmode=disable`
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	log.Println("Successfully connected to database")

	// Initialize DB service and automigrate
	dbService := services.NewDBService(db)
	if err := dbService.Automigrate(); err != nil {
		log.Fatalf("Failed to automigrate database: %v", err)
	}
	log.Println("Database automigration completed successfully")

	// Set up router
	router := mux.NewRouter()

	// Apply logging middleware
	router.Use(LoggingMiddleware)

	// Add routes
	handlers.AddRoutes(router, dbService)
	log.Println("Routes configured successfully")

	// Configure and start server
	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	log.Println("Starting server on :8080")
	if err := srv.ListenAndServe(); err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}

package main

import (
	"first_aid_companion/handlers"
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
)

func main() {
	router := mux.NewRouter()

	handlers.AddRoutes(router)

	srv := &http.Server{
		Addr:    ":8080",
		Handler: router,
	}

	if err := srv.ListenAndServe(); err != nil {
		fmt.Printf("Server failed to start: %v", err)
	}
}

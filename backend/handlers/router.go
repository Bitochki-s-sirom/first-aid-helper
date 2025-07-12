package handlers

import (
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
)

func HomePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello World!")
}

func AddRoutes(r *mux.Router) {
	r.HandleFunc("/", HomePage).Methods("GET")
}

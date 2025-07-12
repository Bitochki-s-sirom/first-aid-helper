package handlers

import (
	_ "first_aid_companion/controllers"
	_ "first_aid_companion/services"
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

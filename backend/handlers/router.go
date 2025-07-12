package handlers

import (
	"first_aid_companion/controllers"
	_ "first_aid_companion/controllers"
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
)

func HomePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello World!")
}

func AddRoutes(r *mux.Router, dbService *services.DBService) {

	userService := controllers.UserService{DB: }
	r.HandleFunc("/", HomePage).Methods("GET")
	r.HandleFunc("/signup")
}

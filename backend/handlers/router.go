package handlers

import (
	"first_aid_companion/controllers"
	"first_aid_companion/services"
	"fmt"
	"net/http"

	"github.com/gorilla/mux"
)

func HomePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello World!")
}

func AddRoutes(r *mux.Router, service *services.DBService) {

	userService := controllers.UserService{DB: service.UserDB}
	r.HandleFunc("/", HomePage).Methods("GET")
	r.HandleFunc("/signup", userService.SignUp).Methods("POST")
	r.HandleFunc("/login", userService.LogIn).Methods("POST")
}

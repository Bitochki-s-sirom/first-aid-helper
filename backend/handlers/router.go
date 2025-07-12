package handlers

import (
	"first_aid_companion/controllers"
	"first_aid_companion/services"
	"fmt"
	"net/http"

	_ "first_aid_companion/docs"

	"github.com/gorilla/mux"
	httpSwagger "github.com/swaggo/http-swagger"
)

func HomePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello World!")
}

func AddRoutes(r *mux.Router, service *services.DBService) {

	drugsService := controllers.DrugService{DB: service.DrugDB}
	medCardService := controllers.MedicalCardService{DB: service.MedCardDB}
	userService := controllers.UserService{DB: service.UserDB, CardService: &medCardService}

	r.HandleFunc("/", HomePage).Methods("GET")
	r.HandleFunc("/signup", userService.SignUp).Methods("POST")
	r.HandleFunc("/login", userService.LogIn).Methods("POST")
	r.PathPrefix("/swagger/").Handler(httpSwagger.WrapHandler)

	authRoute := r.PathPrefix("/auth").Subrouter()
	authRoute.Use(RequireUserMiddleware)
	authRoute.HandleFunc("/me", userService.Me).Methods("GET")
	authRoute.HandleFunc("/drugs", drugsService.Drugs).Methods("GET")
}

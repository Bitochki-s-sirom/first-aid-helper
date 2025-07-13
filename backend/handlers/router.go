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

// Test page for debug
func HomePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "Hello World!")
}

// Populates router with endpoints
func AddRoutes(r *mux.Router, service *services.DBService) {

	// Services initialization
	drugsService := controllers.DrugService{DB: service.DrugDB}
	medCardService := controllers.MedicalCardService{DB: service.MedCardDB}
	userService := controllers.UserService{DB: service.UserDB, CardService: &medCardService}
	chatService := controllers.ChatService{DB: service.ChatDB}
	messageService := controllers.MessageService{ApiKey: service.ApiKey, DB: service.MessageDB}
	documentsService := controllers.DocumentService{DB: service.DocsDB}

	// Non-auth related endpoints
	r.HandleFunc("/", HomePage).Methods("GET")
	r.HandleFunc("/signup", userService.SignUp).Methods("POST")
	r.HandleFunc("/login", userService.LogIn).Methods("POST")
	r.PathPrefix("/swagger/").Handler(httpSwagger.WrapHandler)

	// Auth related endpoints
	authRoute := r.PathPrefix("/auth").Subrouter()
	authRoute.Use(RequireUserMiddleware)

	// Personal info
	authRoute.HandleFunc("/me", userService.Me).Methods("GET")
	authRoute.HandleFunc("/me", userService.UpdateMe).Methods("POST")

	// Drugs storage
	authRoute.HandleFunc("/drugs", drugsService.Drugs).Methods("GET")
	authRoute.HandleFunc("/drugs/add", drugsService.AddDrug).Methods("POST")
	authRoute.HandleFunc("/drugs/remove/{id:[0-9]+}", drugsService.RemoveDrug).Methods("POST")

	// Personal documents (medical prescriptions, illness records etc)
	authRoute.HandleFunc("/documents", documentsService.Documents).Methods("GET")
	authRoute.HandleFunc("/documents/add", documentsService.AddDocument).Methods("POST")
	authRoute.HandleFunc("/documents/remove/{id:[0-9]+}", documentsService.RemoveDocument).Methods("POST")

	// Chat with AI
	authRoute.HandleFunc("/chats", chatService.GetUsersChats).Methods("GET")
	authRoute.HandleFunc("/new_chat", chatService.NewChat).Methods("POST")
	authRoute.HandleFunc("/chats/{id:[0-9]+}", chatService.GetChat).Methods("GET")
	authRoute.HandleFunc("/send_message", messageService.NewMessage).Methods("POST")
}

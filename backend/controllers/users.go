package controllers

import (
	"errors"
	"first_aid_companion/models"
	"log"
	"net/http"
	"regexp"
	"strconv"

	"gorm.io/gorm"
)

// User struct defines the expected user input for signup and login.
type User struct {
	Name     string `json:"name" example:"Aspirin"`
	Email    string `json:"email" example:"Aspirin@asperinovish.ru"`
	Password string `json:"password" example:"Aspirin"`
}

// UserUpdates defines the fields that a user can update in their profile.
type UserUpdates struct {
	Passport    string `json:"passport"`
	Snils       string `json:"snils"`
	Address     string `json:"address"`
	Allergies   string `json:"allergies"`
	ChronicCond string `json:"chronic_cond"`
	BloodType   string `json:"blood_type"`
}

// UserService provides methods to interact with user data and related services.
type UserService struct {
	DB          *models.UserGorm    // Database interface for user data
	CardService *MedicalCardService // Service to handle medical card related logic
}

// Validate checks the User struct fields for basic validity.
// The parameters allow skipping validation for name or email if needed.
func (u *User) Validate(withoutName, withoutEmail bool) error {
	if !withoutName && u.Name == "" {
		return errors.New("empty name")
	}

	if !withoutEmail && u.Email == "" {
		return errors.New("empty email")
	}

	if len(u.Password) < 6 {
		return errors.New("invalid password length")
	}

	// Simple regex to check email format
	emailRegex := regexp.MustCompile(`^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`)
	if !emailRegex.MatchString(u.Email) {
		return errors.New("wrong email format")
	}

	return nil
}

// @Summary Sign up a new user
// @Description Creates a new user account
// @Tags users
// @Accept json
// @Produce json
// @Param input body User true "signup body"
// @Success 200 {object} APIResponse
// @Router /signup [post]
func (us *UserService) SignUp(w http.ResponseWriter, r *http.Request) {
	newUser := &User{}

	// Parse incoming JSON request body into newUser struct
	if err := ParseJSON(r, newUser); err != nil {
		log.Printf("Error parsing JSON in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Validate user input fields (name, email, password)
	if err := newUser.Validate(false, false); err != nil {
		log.Printf("Validation error in SignUp: %v", err)
		WriteError(w, 403, err.Error())
		return
	}

	// Check if a user with this email already exists
	user, err := us.DB.GetUserByEmail(newUser.Email)
	if err == nil && user != nil {
		log.Printf("User already exists: %s", newUser.Email)
		WriteError(w, 409, "user already exists")
		return
	}
	// Handle database errors (except record not found)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		log.Printf("Database error in SignUp: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	// Hash the password before saving to DB
	passwordHash, err := HashPassword(newUser.Password)
	if err != nil {
		log.Printf("Error hashing password in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Create the user record in the database
	createdUser, err := us.DB.CreateUser(newUser.Name, newUser.Email, passwordHash)
	if err != nil {
		log.Printf("Error creating user in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Create an associated medical card for the user
	medCard, err := us.CardService.CreateCard(createdUser.ID)
	if err != nil {
		log.Printf("Error creating Medical card in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Assign the created medical card to the user and update the record
	createdUser.MedicalCard = *medCard
	if err := us.DB.UpdateUser(createdUser); err != nil {
		log.Printf("Error assigning Medical card in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Convert user ID to string for JWT generation
	idAsString := strconv.Itoa(int(createdUser.ID))

	// Generate JWT token for the newly created user
	token, err := GenerateJWT(idAsString, createdUser.Email)
	if err != nil {
		log.Printf("Error generating JWT in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	log.Printf("User signed up successfully: %s", createdUser.Email)

	// Return JWT token in the response
	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   token,
	})
}

// @Summary Log in a user
// @Description Authenticates a user and returns a JWT
// @Tags users
// @Accept json
// @Produce json
// @Param input body User true "login body"
// @Success 200 {object} APIResponse
// @Router /login [post]
func (us *UserService) LogIn(w http.ResponseWriter, r *http.Request) {
	user := &User{}

	// Parse JSON body to extract login credentials
	if err := ParseJSON(r, user); err != nil {
		log.Printf("Error parsing JSON in LogIn: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Validate only the email and password (name not required for login)
	if err := user.Validate(true, false); err != nil {
		log.Printf("Validation error in LogIn: %v", err)
		WriteError(w, 403, err.Error())
		return
	}

	// Retrieve user record by email
	found, err := us.DB.GetUserByEmail(user.Email)
	if err != nil {
		log.Printf("Database error in LogIn: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Compare provided password with stored hash
	if !CheckPasswordHash(user.Password, found.PasswordHash) {
		log.Printf("Invalid password for email: %s", user.Email)
		WriteError(w, 401, "not valid password")
		return
	}

	// Convert user ID to string for token generation
	idAsString := strconv.Itoa(int(found.ID))

	// Generate JWT token upon successful authentication
	token, err := GenerateJWT(idAsString, found.Email)
	if err != nil {
		log.Printf("Error generating JWT in LogIn: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	log.Printf("User logged in successfully: %s", found.Email)

	// Return the JWT token in the response
	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   token,
	})
}

// @Summary Get current user
// @Description Retrieves the authenticated user's details
// @Tags users
// @Accept json
// @Produce json
// @Success 200 {object} APIResponse
// @Router /me [get]
func (us *UserService) Me(w http.ResponseWriter, r *http.Request) {
	// Get user ID from request context (set by authentication middleware)
	userID, userEmail, err := GetUserFromContext(r.Context(), us.DB.DB)
	if err != nil || userID == -1 {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Fetch user details by ID
	user, err := us.DB.GetUserByEmail(userEmail)
	if err != nil {
		log.Printf("Error getting user by ID in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Fetch user's medical card details
	medCard, err := us.CardService.DB.GetCardByUserID(user.ID)
	if err != nil {
		log.Printf("Error getting medical card in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Prepare response data combining user and medical card info
	userData := map[string]interface{}{
		"name":               user.Name,
		"email":              user.Email,
		"snils":              user.SNILS,
		"passport":           user.Passport,
		"address":            user.Address,
		"allergies":          medCard.Allergies,
		"chronic_conditions": medCard.ChronicCond,
		"blood_type":         medCard.BloodType,
	}

	log.Printf("User data retrieved for email: %s", user.Email)

	// Write combined user data as JSON response
	WriteJSON(w, 200, userData)
}

// UpdateMe godoc
// @Summary Update user's profile
// @Description Updates user's personal details and medical card info
// @Tags users
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param input body UserUpdates true "Fields to update"
// @Success 200 {object} APIResponse
// @Failure 400 {object} APIResponse "Bad request"
// @Failure 500 {object} APIResponse "Server error"
// @Router /auth/me [post]
func (us *UserService) UpdateMe(w http.ResponseWriter, r *http.Request) {
	// Get user id from request context
	userID, userEmail, err := GetUserFromContext(r.Context(), us.DB.DB)
	if err != nil || userID == -1 {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Get user by id
	user, err := us.DB.GetUserByEmail(userEmail)
	if err != nil {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Parse JSON to UserUpdates instance
	userUpdates := &UserUpdates{}
	if err := ParseJSON(r, userUpdates); err != nil {
		log.Printf("Error updating user in update Me while parsing JSON: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Replace non-empty fields
	if userUpdates.Address != "" {
		user.Address = userUpdates.Address
	}
	if userUpdates.Passport != "" {
		user.Passport = userUpdates.Passport
	}
	if userUpdates.Snils != "" {
		user.SNILS = userUpdates.Snils
	}

	// Save updates
	if err := us.DB.UpdateUser(user); err != nil {
		log.Printf("Error updating user data in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Ger user's medical card
	medCard, err := us.CardService.DB.GetCardByUserID(user.ID)
	if err != nil {
		log.Printf("Error getting medical card in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	// Replace non-empty fields
	if userUpdates.Allergies != "" {
		medCard.Allergies = userUpdates.Allergies
	}
	if userUpdates.ChronicCond != "" {
		medCard.ChronicCond = userUpdates.ChronicCond
	}
	if userUpdates.BloodType != "" {
		medCard.BloodType = userUpdates.BloodType
	}

	// Save updates
	if err := us.CardService.UpdateCard(medCard); err != nil {
		log.Printf("Error getting medical card in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, nil)

	log.Println("Successfully updated user and med card")
}

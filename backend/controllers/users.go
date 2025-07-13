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

type User struct {
	Name     string `json:"name" example:"Aspirin"`
	Email    string `json:"email" example:"Aspirin@asperinovish.ru"`
	Password string `json:"password" example:"Aspirin"`
}

type UserUpdates struct {
	Passport    string `json:"passport"`
	Snils       string `json:"snils"`
	Address     string `json:"address"`
	Allergies   string `json:"allergies"`
	ChronicCond string `json:"chronic_cond"`
	BloodType   string `json:"blood_type"`
}

type UserService struct {
	DB          *models.UserGorm
	CardService *MedicalCardService
}

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
	log.Printf("Processing SignUp request for email: %s", newUser.Email)
	if err := ParseJSON(r, newUser); err != nil {
		log.Printf("Error parsing JSON in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	if err := newUser.Validate(false, false); err != nil {
		log.Printf("Validation error in SignUp: %v", err)
		WriteError(w, 403, err.Error())
		return
	}

	user, err := us.DB.GetUserByEmail(newUser.Email)
	if err == nil && user != nil {
		log.Printf("User already exists: %s", newUser.Email)
		WriteError(w, 409, "user already exists")
		return
	}

	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		log.Printf("Database error in SignUp: %v", err)
		WriteError(w, 500, "database error")
		return
	}

	passwordHash, err := HashPassword(newUser.Password)
	if err != nil {
		log.Printf("Error hashing password in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	createdUser, err := us.DB.CreateUser(newUser.Name, newUser.Email, passwordHash)
	if err != nil {
		log.Printf("Error creating user in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	medCard, err := us.CardService.CreateCard(createdUser.ID)
	if err != nil {
		log.Printf("Error creating Medical card in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	createdUser.MedicalCard = *medCard
	if err := us.DB.UpdateUser(createdUser); err != nil {
		log.Printf("Error assigning Medical card in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	idAsString := strconv.Itoa(int(createdUser.ID))

	token, err := GenerateJWT(idAsString, createdUser.Email)
	if err != nil {
		log.Printf("Error generating JWT in SignUp: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	log.Printf("User signed up successfully: %s", createdUser.Email)
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
	log.Printf("Processing LogIn request for email: %s", user.Email)
	if err := ParseJSON(r, user); err != nil {
		log.Printf("Error parsing JSON in LogIn: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	if err := user.Validate(true, false); err != nil {
		log.Printf("Validation error in LogIn: %v", err)
		WriteError(w, 403, err.Error())
		return
	}

	found, err := us.DB.GetUserByEmail(user.Email)
	if err != nil {
		log.Printf("Database error in LogIn: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	if !CheckPasswordHash(user.Password, found.PasswordHash) {
		log.Printf("Invalid password for email: %s", user.Email)
		WriteError(w, 401, "not valid password")
		return
	}

	idAsString := strconv.Itoa(int(found.ID))

	token, err := GenerateJWT(idAsString, found.Email)
	if err != nil {
		log.Printf("Error generating JWT in LogIn: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	log.Printf("User logged in successfully: %s", found.Email)
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
	userID, err := GetUserFromContext(r.Context())
	if err != nil || userID == -1 {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	user, err := us.DB.GetUserByID(userID)
	if err != nil {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	medCard, err := us.CardService.DB.GetCardByUserID(user.ID)
	if err != nil {
		log.Printf("Error getting medical card in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

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
	WriteJSON(w, 200, userData)

	log.Printf("User name: %s", user.Name)
}

func (us *UserService) UpdateMe(w http.ResponseWriter, r *http.Request) {
	userID, err := GetUserFromContext(r.Context())
	if err != nil || userID == -1 {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	user, err := us.DB.GetUserByID(userID)
	if err != nil {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	userUpdates := &UserUpdates{}
	if err := ParseJSON(r, userUpdates); err != nil {
		log.Printf("Error updating user in update Me while parsing JSON: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	if userUpdates.Address != "" {
		user.Address = userUpdates.Address
	}
	if userUpdates.Passport != "" {
		user.Passport = userUpdates.Passport
	}
	if userUpdates.Snils != "" {
		user.SNILS = userUpdates.Snils
	}

	if err := us.DB.UpdateUser(user); err != nil {
		log.Printf("Error updating user data in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	medCard, err := us.CardService.DB.GetCardByUserID(user.ID)
	if err != nil {
		log.Printf("Error getting medical card in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	if userUpdates.Allergies != "" {
		medCard.Allergies = userUpdates.Allergies
	}
	if userUpdates.ChronicCond != "" {
		medCard.ChronicCond = userUpdates.ChronicCond
	}
	if userUpdates.BloodType != "" {
		medCard.BloodType = userUpdates.BloodType
	}

	if err := us.CardService.UpdateCard(medCard); err != nil {
		log.Printf("Error getting medical card in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, nil)

	log.Println("Successfully updated user and med card")
}

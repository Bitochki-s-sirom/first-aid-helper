package controllers

import (
	"errors"
	"first_aid_companion/models"
	"log"
	"net/http"
	"regexp"
	"strconv"

	"context"

	"gorm.io/gorm"
)

type User struct {
	Name     string `json:"name"`
	Email    string `json:"email"`
	Password string `json:"password"`
}

type UserService struct {
	DB *models.UserGorm
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
// @Success 200 {object} User
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
// @Success 200 {object} User
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

func (us *UserService) GetUserFromContext(ctx context.Context) (*models.User, error) {
	claims, ok := ctx.Value("user").(*Claims)
	if !ok || claims == nil {
		return nil, errors.New("no user in context")
	}

	id, err := strconv.Atoi(claims.UserID)
	if err != nil {
		log.Printf("Error parsing user ID from context: %v", err)
		return nil, err
	}

	return us.DB.GetUserByID(id)
}

// @Summary Get current user
// @Description Retrieves the authenticated user's details
// @Tags users
// @Accept json
// @Produce json
// @Success 200 {object} User
// @Router /me [get]
func (us *UserService) Me(w http.ResponseWriter, r *http.Request) {
	user, err := us.GetUserFromContext(r.Context())
	if err != nil || user == nil {
		log.Printf("Error getting user from context in Me: %v", err)
		WriteError(w, 500, err.Error())
		return
	}

	userData := map[string]interface{}{
		"name":     user.Name,
		"email":    user.Email,
		"snils":    user.SNILS,
		"passport": user.Passport,
		"address":  user.Address,
	}

	log.Printf("User data retrieved for email: %s", user.Email)
	WriteJSON(w, 200, userData)

	// Replaced fmt.Fprintln(w, user.Name) to log to console instead of response
	log.Printf("User name: %s", user.Name)
}

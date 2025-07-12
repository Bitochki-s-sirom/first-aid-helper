package controllers

import (
	"errors"
	"first_aid_companion/models"
	"fmt"
	"net/http"
	"regexp"
	"strconv"

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

// @Summary Описание
// @Description Детальное описание
// @Tags users
// @Accept json
// @Produce json
// @Success 200 {object} User
// @Router /signup [post]
func (us *UserService) SignUp(w http.ResponseWriter, r *http.Request) {
	newUser := &User{}

	if err := ParseJSON(r, newUser); err != nil {
		WriteError(w, 500, err.Error())
		return
	}

	if err := newUser.Validate(false, false); err != nil {
		WriteError(w, 403, err.Error())
		return
	}

	user, err := us.DB.GetUserByEmail(newUser.Email)
	fmt.Print(user)
	if err == nil && user != nil {
		WriteError(w, 409, "user already exists")
		return
	}

	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		WriteError(w, 500, "database error")
		return
	}

	passwordHash, err := HashPassword(newUser.Password)
	if err != nil {
		WriteError(w, 500, err.Error())
		return
	}

	createdUser, err := us.DB.CreateUser(newUser.Name, newUser.Email, passwordHash)
	if err != nil {
		WriteError(w, 500, err.Error())
		return
	}

	idAsString := strconv.Itoa(int(createdUser.ID))

	token, err := GenerateJWT(idAsString, createdUser.Email)
	if err != nil {
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   token,
	})
}

// @Summary Описание
// @Description Детальное описание
// @Tags users
// @Accept json
// @Produce json
// @Success 200 {object} User
// @Router /login [post]
func (us *UserService) LogIn(w http.ResponseWriter, r *http.Request) {
	user := &User{}

	if err := ParseJSON(r, user); err != nil {
		WriteError(w, 500, err.Error())
		return
	}

	if err := user.Validate(true, false); err != nil {
		WriteError(w, 403, err.Error())
		return
	}

	found, err := us.DB.GetUserByEmail(user.Email)
	if err != nil {
		WriteError(w, 500, err.Error())
		return
	}

	if !CheckPasswordHash(user.Password, found.PasswordHash) {
		WriteError(w, 401, "not valid password")
		return
	}

	idAsString := strconv.Itoa(int(found.ID))

	token, err := GenerateJWT(idAsString, found.Email)
	if err != nil {
		WriteError(w, 500, err.Error())
		return
	}

	WriteJSON(w, 200, &APIResponse{
		Status: 200,
		Data:   token,
	})
}

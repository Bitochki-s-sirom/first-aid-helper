package controllers

import (
	"net/http"
	"first_aid_companion/models"
)

type User {
	Nam
}
type UserService struct {
	DB *models.ChatGorm
}

func (us *UserService) CreateUser(w http.ResponseWriter, r *http.Request) {

}
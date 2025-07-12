package controllers

import "first_aid_companion/models"

type MedicalCardService struct {
	DB *models.MedicalCardGorm
}

func (ms *MedicalCardService) CreateCard(userID uint) (*models.MedicalCard, error) {
	return ms.DB.CreateCard("", "", "", userID)
}

func (ms *MedicalCardService) GetCard(useriD uint) (*models.MedicalCard, error) {
	return ms.DB.GetCardByUserID(useriD)
}

func (ms *MedicalCardService) UpdateCard(medCard *models.MedicalCard) error {
	return ms.DB.UpdateCard(medCard)
}

package models

import "gorm.io/gorm"

type Group struct {
	ID          uint `gorm:"primaryKey"`
	Name        string
	Description string
	Members     []User `gorm:"many2many:user_groups;"`
}

type GroupGorm struct {
	DB *gorm.DB
}

func (gg *GroupGorm) CreateGroup(args map[string]interface{}) (*Group, error) {
	group := &Group{}

	if val, ok := args["Name"].(string); ok {
		group.Name = val
	}
	if val, ok := args["Description"].(string); ok {
		group.Description = val
	}
	if val, ok := args["Members"].([]User); ok {
		group.Members = val
	}

	result := gg.DB.Create(group)
	if result.Error != nil {
		return nil, result.Error
	}
	return group, nil
}

func (gg *GroupGorm) GetGroupByID(id uint) (*Group, error) {
	var group Group
	if err := gg.DB.Table("groups").Where("id = ?", id).Scan(&group).Error; err != nil {
		return nil, err
	}
	return &group, nil
}

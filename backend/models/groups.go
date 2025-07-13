package models

import "gorm.io/gorm"

// Group represents a group of users.
// It includes a many-to-many relationship with the User model via the join table 'user_groups'.
type Group struct {
	ID          uint   `gorm:"primaryKey"` // Unique identifier for the group
	Name        string // Name of the group
	Description string // Optional description of the group's purpose
	Members     []User `gorm:"many2many:user_groups;"` // Many-to-many relationship with users
}

// GroupGorm wraps the GORM DB instance for performing database operations related to Group.
type GroupGorm struct {
	DB *gorm.DB
}

// CreateGroup creates a new group record in the database.
// It accepts a map of arguments to populate the group's fields.
// The map can include keys: "Name" (string), "Description" (string), and "Members" ([]User).
func (gg *GroupGorm) CreateGroup(args map[string]interface{}) (*Group, error) {
	group := &Group{}

	// Extract fields from args map if present
	if val, ok := args["Name"].(string); ok {
		group.Name = val
	}
	if val, ok := args["Description"].(string); ok {
		group.Description = val
	}
	if val, ok := args["Members"].([]User); ok {
		group.Members = val
	}

	// Create the group in the database
	result := gg.DB.Create(group)
	if result.Error != nil {
		return nil, result.Error
	}
	return group, nil
}

// GetGroupByID retrieves a group by its ID.
// Returns the group if found, or an error otherwise.
func (gg *GroupGorm) GetGroupByID(id uint) (*Group, error) {
	var group Group
	if err := gg.DB.Table("groups").Where("id = ?", id).First(&group).Error; err != nil {
		return nil, err
	}
	return &group, nil
}

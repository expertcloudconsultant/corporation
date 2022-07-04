

#Create Locations - Availability Zones
variable "avzs" {
  default = ["uksouth", "ukwest", "eastus", "westeurope"]
}


#Prefix for Corporation
variable "corp" {
  default = "corporate"
}

variable "env" {
  default = ["prod", "staging", "dev"]
}

variable "locations" {
  default = ["uksouth", "ukwest", "eastus", "westeurope"]
}
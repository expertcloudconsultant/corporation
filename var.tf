#Create Locations - Availability Zones
variable "avzs" {
  default = ["uksouth", "ukwest", "eastus", "westeurope"]
}


#Prefix for Corporation
variable "corp" {
  default = "corporate"
}


#Load  Balancer Constructs
variable "private_ip" {
  default = "10.20.0.100"
}



variable "env" {
  default = "Static"
}
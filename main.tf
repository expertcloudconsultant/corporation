#Create Resource Groups
resource "azurerm_resource_group" "corporate-production-rg" {
  name     = "corporate-production-rg"
  location = var.avzs[0] #Avaialability Zone 0 always marks your Primary Region.
}


resource "azurerm_availability_set" "vmavset" {
  name                = "vmavset"
  location            = azurerm_resource_group.corporate-production-rg.location
  resource_group_name = azurerm_resource_group.corporate-production-rg.name
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
  tags = {
    environment = "Production"
  }
}


#Create Virtual Networks > Create Hub Virtual Network
resource "azurerm_virtual_network" "corporate-hub-vnet" {
  name                = "corporate-hub-vnet"
  location            = azurerm_resource_group.corporate-production-rg.location
  resource_group_name = azurerm_resource_group.corporate-production-rg.name
  address_space       = ["172.20.0.0/16"]

  tags = {
    environment = "Hub Network"
  }
}

#Create Hub Azure Gateway Subnet
resource "azurerm_subnet" "hub-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.corporate-production-rg.name
  virtual_network_name = azurerm_virtual_network.corporate-hub-vnet.name
  address_prefixes     = ["172.20.0.0/24"]
}


#Create Virtual Networks > Create Spoke Virtual Network
resource "azurerm_virtual_network" "corporate-prod-vnet" {
  name                = "corporate-prod-vnet"
  location            = azurerm_resource_group.corporate-production-rg.location
  resource_group_name = azurerm_resource_group.corporate-production-rg.name
  address_space       = ["10.20.0.0/16"]

  tags = {
    environment = "Production Network"
  }
}

#Create Hub Azure Gateway Subnet
resource "azurerm_subnet" "business-tier-subnet" {
  name                 = "business-tier-subnet"
  resource_group_name  = azurerm_resource_group.corporate-production-rg.name
  virtual_network_name = azurerm_virtual_network.corporate-prod-vnet.name
  address_prefixes     = ["10.20.0.0/24"]
}



##########virtual##################network#############peering###########################
#Create Network Peering from Hub to Spoke
resource "azurerm_virtual_network_peering" "hub-to-prod-spoke-peering" {
  name                      = "hub-corp-spoke-peering"
  resource_group_name       = azurerm_resource_group.corporate-production-rg.name
  virtual_network_name      = azurerm_virtual_network.corporate-hub-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.corporate-prod-vnet.id
}
##########virtual##################network#############peering###########################



##########virtual##################network#############peering###########################
#Create Network Peering from Spoke to Hub
resource "azurerm_virtual_network_peering" "corp-to-hub-spoke-peering" {
  name                      = "corp-hub-spoke-peering"
  resource_group_name       = azurerm_resource_group.corporate-production-rg.name
  virtual_network_name      = azurerm_virtual_network.corporate-prod-vnet.name
  remote_virtual_network_id = azurerm_virtual_network.corporate-hub-vnet.id
}
##########virtual##################network#############peering###########################



#Create Private Network Interfaces
resource "azurerm_network_interface" "corpnic" {
  name                = "corpnic-${count.index + 1}"
  location            = azurerm_resource_group.corporate-production-rg.location
  resource_group_name = azurerm_resource_group.corporate-production-rg.name
  count               = 2

  ip_configuration {
    name                          = "ipconfig-${count.index + 1}"
    subnet_id                     = azurerm_subnet.business-tier-subnet.id
    private_ip_address_allocation = "Dynamic"

  }
}


#Create Load Balancer
resource "azurerm_lb" "business-tier-lb" {
  name                = "business-tier-lb"
  location            = azurerm_resource_group.corporate-production-rg.location
  resource_group_name = azurerm_resource_group.corporate-production-rg.name

  frontend_ip_configuration {
    name                          = "businesslbfrontendip"
    subnet_id                     = azurerm_subnet.business-tier-subnet.id
    private_ip_address            = var.env == "Static" ? var.private_ip : null
    private_ip_address_allocation = var.env == "Static" ? "Static" : "Dynamic"
  }
}


#Create Backend Address Pool
resource "azurerm_lb_backend_address_pool" "business-backend-pool" {
  loadbalancer_id = azurerm_lb.business-tier-lb.id
  name            = "business-backend-pool"
}



#Automated Backend Pool Addition
resource "azurerm_network_interface_backend_address_pool_association" "business-tier-pool" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.corpnic.*.id[count.index]
  ip_configuration_name   = azurerm_network_interface.corpnic.*.ip_configuration.0.name[count.index]
  backend_address_pool_id = azurerm_lb_backend_address_pool.business-backend-pool.id

}


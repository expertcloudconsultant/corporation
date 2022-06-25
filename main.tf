#Create Resource Groups
resource "azurerm_resource_group" "corporate-production-rg" {
  name     = "corporate-production-rg"
  location = var.avzs[0] #Avaialability Zone 0 always marks your Primary Region.
}




#Create Virtual Networks

#Create Hub Virtual Network
resource "azurerm_virtual_network" "corp-hub-vnet" {
  name                = "${var.corp}-hub-vnet"
  location            = azurerm_resource_group.corporate-production-rg.location
  resource_group_name = azurerm_resource_group.corporate-production-rg.name
  address_space       = ["172.20.0.0/16"]

  tags = {
    environment = "Hub Network"
  }
}


#Create GateWay Subnets

#Create Hub Azure Gateway Subnet
resource "azurerm_subnet" "hub-gateway-subnet" {

  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.corporate-production-rg.name
  virtual_network_name = azurerm_virtual_network.corp-hub-vnet.name
  address_prefixes     = ["172.20.0.0/24"]
  
}







#Create NSGs


#Associate NSGs to Subnets


#Create Virtual Machine NICs


#Create Load Balancer


#Create Backend Address Pool



#Create NAT Rule(s)



#Create Load Balancing Rules



#Create Load Balancing Probes



#Associate BackendPool to NICs using resident Subnet



#
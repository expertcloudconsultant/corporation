#Create Resource Groups
resource "azurerm_resource_group" "corporate-production-rg" {
  name     = "corporate-production-rg"
  location = "${var.avzs[0]}" #Avaialability Zone 0 always marks your Primary Region.
}


#Create Virtual Networks > Create Hub Virtual Network
resource "azurerm_virtual_network" "corporate-hub-vnet" {
  name                = "${var.corp}-hub-vnet"
  location            = "${var.avzs[0]}"
  resource_group_name = "azurerm_resource_group.${var.corp}-production-rg.name"
  address_space       = ["172.20.0.0/16"]

  tags = {
    environment = "Hub Network"
  }
}


#Create Hub Azure Gateway Subnet
resource "azurerm_subnet" "hub-gateway-subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = "azurerm_resource_group.${var.corp}-production-rg.name"
  virtual_network_name = "azurerm_virtual_network.${var.corp}-hub-vnet.name"
  address_prefixes     = ["172.20.0.0/24"]
}


#Create Virtual Networks > Create Spoke Virtual Networks
resource "azurerm_virtual_network" "corporate-prod-vnet" {
  name                = "${var.corp}-prod-vnet"
  location            = "${var.avzs[0]}"
  resource_group_name = "azurerm_resource_group.${var.corp}-production-rg.name"
  address_space       = ["10.10.0.0/16"]
  tags = {
    environment = "Production Network"
  }
}


#Create Production Subnets
resource "azurerm_subnet" "corporate-business-tier" {
  name                 = "${var.corp}-business-tier"
  resource_group_name  = "azurerm_resource_group.${var.corp}-production-rg.name"
  virtual_network_name = "azurerm_virtual_network.${var.corp}-prod-vnet.name"
  address_prefixes     = ["10.10.10.0/24"]

}

#Create Peering between Hub and Spoke Networks
#Hub to Production Spoke

resource "azurerm_virtual_network_peering" "hub-to-prod-spoke-peering" {
  name                      = "${var.corp}-hub-to-${var.corp}-prod-peering"
  resource_group_name       = "azurerm_resource_group.${var.corp}-production-rg.name"
  virtual_network_name      = "azurerm_virtual_network.${var.corp}-hub-vnet.name"
  remote_virtual_network_id = "azurerm_virtual_network.${var.corp}-prod-vnet.id"
}


resource "azurerm_virtual_network_peering" "prod-spoke-to-hub-peering" {
  name                      = "${var.corp}-prod-to-${var.corp}-hub-peering"
  resource_group_name       = "azurerm_resource_group.${var.corp}-production-rg.name"
  virtual_network_name      = "azurerm_virtual_network.${var.corp}-prod-vnet.name"
  remote_virtual_network_id = "azurerm_virtual_network.${var.corp}-hub-vnet.id"
}



#Create NSGs


#Associate NSGs to Subnets


#Create Virtual Machine NICs


#Create Public IP Address
resource "azurerm_public_ip" "lb-pub-ip" {
  name                = "lb-pub-ip"
  location            = "${var.avzs[0]}"
  resource_group_name = "azurerm_resource_group.${var.corp}-production-rg.name"
  allocation_method   = "Dynamic"
  domain_name_label   = "lb-pub-ip" # UNIQUE
}


#Create Load Balancer
resource "azurerm_lb" "corporate-business-tier-lb" {
  name                = "${var.corp}-business-tier-lb"
  location            = "${var.avzs[0]}"
  resource_group_name = "azurerm_resource_group.${var.corp}-production-rg.name"

  frontend_ip_configuration {
    name                 = "businesslbfrontendip"
    public_ip_address_id = azurerm_public_ip.lb-pub-ip.id
  }
}



#Create Backend Address Pool
resource "azurerm_lb_backend_address_pool" "business_backend_pool" {
  #resource_group_name = "azurerm_resource_group.${var.corp}-production-rg.name" 
  loadbalancer_id = azurerm_lb.corporate-business-tier-lb.id
  name            = "businessbackendpool"
}


#Create NAT Rule(s)



#Create Load Balancing Rules
resource "azurerm_lb_rule" "business_lb_rule" {
  resource_group_name            = "azurerm_resource_group.${var.corp}-production-rg.name"
  loadbalancer_id                = azurerm_lb.corporate-business-tier-lb.id
  name                           = "LBRule"
  protocol                       = "tcp"
  frontend_port                  = "22"
  backend_port                   = "22"
  frontend_ip_configuration_name = "businesslbfrontendip"
  enable_floating_ip             = false
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.business_backend_pool.id]
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.business_lb_probe.id # not created yet 
  depends_on                     = [azurerm_lb_probe.business_lb_probe]

}

#Create Load Balancing Probes

resource "azurerm_lb_probe" "business_lb_probe" {
  resource_group_name = "azurerm_resource_group.${var.corp}-production-rg.name"
  loadbalancer_id     = azurerm_lb.corporate-business-tier-lb.id
  name                = "businesslbprobe"
  protocol            = "tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}




#Create Private Network Interfaces
resource "azurerm_network_interface" "nic" {
  name                = "${var.corp}-nic-${count.index + 1}"
  location            = "${var.avzs[0]}"
  resource_group_name = "azurerm_resource_group.${var.corp}-production-rg.name"
  count               = 2

  ip_configuration {
    name                          = "ipconfig${count.index + 1}"
    subnet_id                     = azurerm_subnet.corporate-business-tier.id
    private_ip_address_allocation = "Dynamic"
  
  }
}


resource "azurerm_network_interface_backend_address_pool_association" "bepool-nic-association" {
  ip_configuration_name   = "bepool-nic-association"
  backend_address_pool_id = azurerm_lb_backend_address_pool.business_backend_pool.id
  network_interface_id    = element(azurerm_network_interface.nic.*.id, count.index)
  count                   = 2
}



# Create (and display) an SSH key
resource "tls_private_key" "linuxvmsshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


#Create Virtual Machines
#Linux Workloads
resource "azurerm_linux_virtual_machine" "corporate-business-linux-vm" {

  name                  = "${var.corp}businesslinuxvm${count.index}"
  location              = "${var.avzs[0]}"
  resource_group_name   = "azurerm_resource_group.${var.corp}-production-rg.name"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  size                  = "Standard_B1s" # "Standard_D2ads_v5" # "Standard_DC1ds_v3"
  count                 = 2


  #Create Operating System Disk
  os_disk {
    name                 = "${var.corp}disk${count.index}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS" #Consider Storage Type
  }


  #Reference Source Image from Publisher
  source_image_reference {
    publisher = "Canonical"                    #az vm image list -p "Canonical" --output table
    offer     = "0001-com-ubuntu-server-focal" # az vm image list -p "Canonical" --output table
    sku       = "20_04-lts-gen2"               #az vm image list -s "18.04-LTS" --output table
    version   = "latest"
  }


  #Create Computer Name and Specify Administrative User Credentials
  computer_name                   = "${var.corp}-linux-vm01"
  admin_username                  = "linuxsvruser"
  disable_password_authentication = true


  #Create SSH Key for Secured Authentication - on Windows Management Server [Putty + PrivateKey]
  admin_ssh_key {
    username   = "linuxsvruser"
    public_key = tls_private_key.linuxvmsshkey.public_key_openssh
  }



  #Prepare Environment for Cloud Initialised Packages
  custom_data = data.template_cloudinit_config.corporate-vm-config.rendered
}

#Custom Data Insertion Here

data "template_cloudinit_config" "corporate-vm-config" {
  gzip          = true
  base64_encode = true

  part {

    content_type = "text/cloud-config"
    content      = "packages: ['htop','pip','python3']" #specify package to be installed. [ansible, terraform, azurecli]
  }




}



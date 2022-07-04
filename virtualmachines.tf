# Create (and display) an SSH key
resource "tls_private_key" "linuxvmsshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

#Create Virtual Machines
#Linux Workloads
resource "azurerm_linux_virtual_machine" "corporate-business-linux-vm" {

  name                  = "${var.corp}linuxvm${count.index}"
  location              = azurerm_resource_group.corporate-production-rg.location
  resource_group_name   = azurerm_resource_group.corporate-production-rg.name
  availability_set_id   = azurerm_availability_set.vmavset.id
  network_interface_ids = ["${element(azurerm_network_interface.corpnic.*.id, count.index)}"]
  size                  = "Standard_D2s_v3" #"Standard_B1s" # "Standard_D2ads_v5" # "Standard_DC1ds_v3"
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
  computer_name                   = "corporate-linux-vm${count.index}"
  admin_username                  = "linuxsvruser${count.index}"
  disable_password_authentication = true



  #Create SSH Key for Secured Authentication - on Windows Management Server [Putty + PrivateKey]
  admin_ssh_key {
    username   = "linuxsvruser${count.index}"
    public_key = tls_private_key.linuxvmsshkey.public_key_openssh
  }

}
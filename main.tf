provider "azurerm" {
  features {}
}

# Define variables for resource group, VM and network settings
variable "location" {
  default = "Southeast Asia"
}

variable "resource_group_name" {
  default = "test-projectsvm"
}

variable "vm_name" {
  default = "nktestvm005"
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  default = "P@ssw0rd123!" # Change this to a secure password
}

variable "vm_size" {
  default = "Standard_DS2_v2"
}

variable "image_publisher" {
  default = "MicrosoftWindowsServer"
}

variable "image_offer" {
  default = "WindowsServer"
}

variable "image_sku" {
  default = "2019-Datacenter"
}

# Define the resource group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location
}

# Define the virtual network
resource "azurerm_virtual_network" "example" {
  name                = "vnet-terraform-example"
  address_space        = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.example.name
}

# Define the subnet
resource "azurerm_subnet" "example" {
  name                 = "subnet-terraform-example"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define the network interface
resource "azurerm_network_interface" "example" {
  name                      = "nic-terraform-example"
  location                  = var.location
  resource_group_name       = azurerm_resource_group.example.name
  virtual_network_name      = azurerm_virtual_network.example.name
  subnet_id                 = azurerm_subnet.example.id
  private_ip_address_allocation = "Dynamic"
}

# Define the virtual machine
resource "azurerm_windows_virtual_machine" "example" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.example.name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  network_interface_ids = [azurerm_network_interface.example.id]
  os_disk {
    name              = "osdisk-${var.vm_name}"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = var.image_publisher
    offer     = var.image_offer
    sku       = var.image_sku
    version   = "latest"
  }
}

output "vm_public_ip" {
  value = azurerm_network_interface.example.private_ip_address
}

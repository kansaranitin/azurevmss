# Provider Configuration
provider "azurerm" {
  features {}
}

# Define the resource group
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "East US"
}

# Define Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "myVnet"
  address_space        = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Define Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Define Network Interface
resource "azurerm_network_interface" "nic" {
  count               = 2
  name                = "myNIC-${count.index}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet.id

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
  }
}

# Define Windows Virtual Machine Scale Set (VMSS)
resource "azurerm_linux_virtual_machine_scale_set" "windows_vmss" {
  name                     = "myWindowsVMSS"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  upgrade_policy_mode      = "Manual"
  instances                = 2
  sku                      = "Standard_DS1_v2"
  admin_username           = "adminuser"
  admin_password           = "Password1234!"
  os_type                  = "Windows"
  custom_data              = file("init-script.ps1")

  network_interface {
    name                 = "myNIC"
    primary              = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id
  }

  storage_profile {
    os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Premium_LRS"
    }
  }

  # Optional: Diagnostics, Monitoring
  enable_diagnostics = true
}

# Security Group for VMSS
resource "azurerm_network_security_group" "vmss_nsg" {
  name                         = "myVMSS-NSG"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
}

# Output the VMSS IP address
output "public_ip" {
  value = azurerm_linux_virtual_machine_scale_set.windows_vmss.public_ip_address
}

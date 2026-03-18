# 1. Required Providers
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0" 
    }
  }
}

# 2. Configure the Azure Provider
provider "azurerm" {
  features {}
}

# 3. Reference the EXISTING Resource Group
# We use "data" instead of "resource" because it already exists in Azure.
data "azurerm_resource_group" "existing_rg" {
  name = "vj-RG"
}

# 4. Networking: VNET and Subnet
resource "azurerm_virtual_network" "my_vnet" {
  name                = "vj-vnet"
  address_space       = ["10.0.0.0/16"]
  # Note: We now use data.azurerm_resource_group... to get the details
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
}

resource "azurerm_subnet" "my_subnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.existing_rg.name
  virtual_network_name = azurerm_virtual_network.my_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

# 5. Public IP and Network Interface (NIC)
resource "azurerm_public_ip" "my_public_ip" {
  name                = "vj-public-ip"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "my_nic" {
  name                = "vj-nic"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.my_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_public_ip.id
  }
}

# 6. The Virtual Machine
resource "azurerm_linux_virtual_machine" "my_vm" {
  name                = "vj-practice-vm"
  resource_group_name = data.azurerm_resource_group.existing_rg.name
  location            = data.azurerm_resource_group.existing_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"
  
  admin_password                  = "P@ssw0rd1234!" 
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.my_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}


# 7. Network Security Group (NSG) and Rules
resource "azurerm_network_security_group" "my_nsg" {
  name                = "vj-nsg"
  location            = data.azurerm_resource_group.existing_rg.location
  resource_group_name = data.azurerm_resource_group.existing_rg.name

  # Allow SSH (Port 22) from any IP
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.92.188.98"
    destination_address_prefix = "*"
  }
}

# 8. Associate NSG with the Network Interface
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.my_nic.id
  network_security_group_id = azurerm_network_security_group.my_nsg.id
}
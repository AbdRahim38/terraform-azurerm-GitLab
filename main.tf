# AbdulRahim-14032022-v1
# Terraform template to install Gitlab in Azure VM

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

#Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true
  features {}
}

resource "random_string" "fqdn" {
 length  = 6
 special = false
 upper   = false
 number  = false
}

# -- Networking --
# To be block if using ACG sandbox resource group
# resource "azurerm_resource_group" "main" {
#   name     = "${var.prefix}-rg"
#   location = "${var.location}"
# }

resource "azurerm_virtual_network" "main" {
  name          = "${var.prefix}-network"
  address_space = ["10.0.0.0/16"]
  # location            = "${azurerm_resource_group.main.location}"
  # resource_group_name = "${azurerm_resource_group.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "main" {
  name = "${var.prefix}-subnet"
  # resource_group_name  = "${azurerm_resource_group.main.name}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  name = "${var.prefix}-pip"
  # location            = "${azurerm_resource_group.main.location}"
  # resource_group_name = "${azurerm_resource_group.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = "${lower(var.prefix)}-${random_string.fqdn.result}"
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "allow_https"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_http"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "main" {
  name = "${var.prefix}-nic"
  # location            = "${azurerm_resource_group.main.location}"
  # resource_group_name = "${azurerm_resource_group.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "${var.prefix}-ipconfig1"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "${lower(var.prefix)}sa${random_string.fqdn.result}"
    resource_group_name         = var.resource_group_name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# -- Virtual Machine --
resource "azurerm_virtual_machine" "main" {
  name = "${var.prefix}-vm"
  # location            = "${azurerm_resource_group.main.location}"
  # resource_group_name = "${azurerm_resource_group.main.name}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_D2s_v3"

  # This means the OS Disk will be deleted when Terraform destroys the Virtual Machine
  # NOTE: This may not be optimal in all cases.
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  plan {
    name      = "default"
    publisher = "gitlabinc1586447921813"
    product   = "gitlabee"
  }

  storage_image_reference {
    publisher = "gitlabinc1586447921813"
    offer     = "gitlabee"
    sku       = "default"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    os_type           = "Linux"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = var.prefix
    admin_username = var.admin_user
    admin_password = var.admin_password
  }

  boot_diagnostics {
    enabled = "true"
    storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint    
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

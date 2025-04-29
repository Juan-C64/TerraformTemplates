terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.26.0"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

variable "vm_count" {
  default = 2 #Número a cambiar dependiendo del número de maquinas a crear.
}

data "azurerm_resource_group" "rg" {
  name = "Site24x7"
}

data "azurerm_subnet" "subnet" {
  name                 = "default"          #Nombre de la subred en Azure
  virtual_network_name = "Network-site24x7" #Nombre de la Vnet en Azure
  resource_group_name  = data.azurerm_resource_group.rg.name
}


#Bloque de creación y configuración de las interfaces de red
resource "azurerm_network_interface" "nic" {
  count               = var.vm_count
  name                = "PTA-CLI-${count.index + 1}-nic"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig-PTA-CLI-${count.index + 1}"
    subnet_id                     = data.azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}


#Bloque de creación de maquinas virtuales
resource "azurerm_windows_virtual_machine" "vm" {
  count               = var.vm_count
  name                = "PTA-CLI-${count.index + 1}"
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  size                = "Standard_B2s"
  admin_username      = "admin_PT"
  admin_password      = "PT_Adv2025I**"
  network_interface_ids = [
    azurerm_network_interface.nic[count.index].id
  ]

  #Sub-bloque de creación del disco asociado a la vm
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  #Sub bloque de creación de la imagen especifica a utilizar
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "win10-22h2-pro"
    version   = "latest"
  }
}
locals {
  location = {
    eastus = "ue"
  }
  suffix = format("%s-%s-%s",
    local.location[var.location],
    var.environment,
  var.project)
}

resource "azurerm_resource_group" "this" {
  name     = format("rg-%s", local.suffix)
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = format("vn-%s", local.suffix)
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  address_space = [var.network_range]
}

resource "azurerm_subnet" "runners" {
  name                 = format("sn-%s", local.suffix)
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name

  address_prefixes = [cidrsubnet(var.network_range, 0, 0)]
}

# Create public IPs
resource "azurerm_public_ip" "this" {
  name                = format("pip-%s", local.suffix)
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "this" {
  name                = format("sg-%s", local.suffix)
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "this" {
  name                = format("ni-%s", local.suffix)
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.runners.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "this" {
  network_interface_id      = azurerm_network_interface.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.this.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "this" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.this.location
  resource_group_name      = azurerm_resource_group.this.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "runners" {
  name                  = replace(format("vm-%s", local.suffix), "-", "")
  location              = azurerm_resource_group.this.location
  resource_group_name   = azurerm_resource_group.this.name
  network_interface_ids = [azurerm_network_interface.this.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "None"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "myvm"
  admin_username                  = "runner-admin"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "runner-admin"
    public_key = tls_private_key.this.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.this.primary_blob_endpoint
  }
}

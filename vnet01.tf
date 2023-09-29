resource "azurerm_resource_group" "resource_group" {
  name     = "${var.prefix}-rg"
  location = "Central India"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet01"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  depends_on          = [azurerm_resource_group.resource_group]
}

resource "azurerm_subnet" "subnet01" {
  name                 = "subnet01"
  resource_group_name  = azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}

resource "azurerm_network_interface" "vm-nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
  depends_on = [azurerm_subnet.subnet01]
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.resource_group.name
  location                        = azurerm_resource_group.resource_group.location
  size                            = "Standard_F2"
  admin_username                  = "adminuser"
  disable_password_authentication = false
  admin_password                  = "Cubastion#123!"
  network_interface_ids = [
    azurerm_network_interface.vm-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  depends_on = [azurerm_network_interface.vm-nic]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "vm-public-ip"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  allocation_method   = "Static"
}

resource "azurerm_availability_set" "availability_set" {
  name                = "${var.prefix}-aset"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  depends_on          = [azurerm_resource_group.resource_group]
}

resource "azurerm_storage_account" "storage_account" {
  name                = "cubastionstorageaccount"
  resource_group_name = azurerm_resource_group.resource_group.name

  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Premium"
  account_replication_type = "LRS"
  # public_network_access_enabled = false
  depends_on = [azurerm_resource_group.resource_group, azurerm_subnet.subnet01]
}

resource "azurerm_private_endpoint" "example" {
  name                = "${var.prefix}-endpoint"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  subnet_id           = azurerm_subnet.subnet01.id

  private_service_connection {
    name                           = "cubation-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.storage_account.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "endpoint-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zone.id]
  }
  depends_on = [ azurerm_storage_share.fileshare01, azurerm_storage_share.fileshare02 ]
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "example" {
  name                  = "dns-vnet-link"
  resource_group_name   = azurerm_resource_group.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

resource "azurerm_storage_share" "fileshare01" {
  name                 = "fileshare01"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 5
  depends_on           = [azurerm_storage_account.storage_account]
}

resource "azurerm_storage_share" "fileshare02" {
  name                 = "fileshare02"
  storage_account_name = azurerm_storage_account.storage_account.name
  quota                = 5
  depends_on           = [azurerm_storage_account.storage_account]
}
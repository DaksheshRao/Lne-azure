resource "azurerm_resource_group" "resource_group02" {
  name     = "${var.prefix}-agw-rg"
  location = "Central India"
}

resource "azurerm_virtual_network" "vnet02" {
  name                = "vnet02"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.resource_group02.location
  resource_group_name = azurerm_resource_group.resource_group02.name
  depends_on          = [azurerm_resource_group.resource_group02]
}

resource "azurerm_subnet" "subnet02" {
  name                 = "subnet02"
  resource_group_name  = azurerm_resource_group.resource_group02.name
  virtual_network_name = azurerm_virtual_network.vnet02.name
  address_prefixes     = ["10.1.0.0/24"]
  depends_on           = [azurerm_virtual_network.vnet02]
}

resource "azurerm_subnet" "subnet03" {
  name                 = "subnet03"
  resource_group_name  = azurerm_resource_group.resource_group02.name
  virtual_network_name = azurerm_virtual_network.vnet02.name
  address_prefixes     = ["10.1.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet02]
}

resource "azurerm_public_ip" "public_ip02" {
  name                = "vm-public-ip02"
  resource_group_name = azurerm_resource_group.resource_group02.name
  location            = azurerm_resource_group.resource_group02.location
  sku                 = "Standard"
  allocation_method   = "Static"
  depends_on = [ azurerm_resource_group.resource_group02 ]
}


resource "azurerm_application_gateway" "cuba-agw" {
  name                = "${var.prefix}-app-gateway"
  resource_group_name = azurerm_resource_group.resource_group02.name
  location            = azurerm_resource_group.resource_group02.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "${var.prefix}-gateway-ip-config"
    subnet_id = azurerm_subnet.subnet02.id
  }

  frontend_port {
    name = "defaultfrontendport"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "defaultfrontendipconfiguration"
    public_ip_address_id = azurerm_public_ip.public_ip02.id
  }

  backend_address_pool {
    name = "defaultbackendaddresspool"
  }

  backend_http_settings {
    name                  = "defaulthttpSetting"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
  }

  http_listener {
    name                           = "defaulthttpListener"
    frontend_ip_configuration_name = "defaultfrontendipconfiguration"
    frontend_port_name             = "defaultfrontendport"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "httpRoutingRule"
    rule_type                  = "Basic"
    priority                   = "200"
    http_listener_name         = "defaulthttpListener"
    backend_address_pool_name  = "defaultbackendaddresspool"
    backend_http_settings_name = "defaulthttpSetting"
  }
  depends_on = [ azurerm_resource_group.resource_group02, azurerm_subnet.subnet02, azurerm_public_ip.public_ip02 ]
}



resource "azurerm_kubernetes_cluster" "k8s-cluster" {
  name                = "${var.prefix}-k8s-cluster"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  dns_prefix          = "${var.prefix}-k8s-cluster-dns"

  default_node_pool {
    name           = "default"
    node_count     = 1
    vm_size        = "Standard_DS2_v2"
    vnet_subnet_id = azurerm_subnet.subnet03.id
  }

  network_profile {
    network_plugin = "azure"
  }

  identity {
    type = "SystemAssigned"
  }

  ingress_application_gateway {
    gateway_id = azurerm_application_gateway.cuba-agw.id
  }

  role_based_access_control_enabled = true
  private_cluster_enabled           = true

  depends_on = [
    azurerm_application_gateway.cuba-agw,
  ]
}

# resource "azurerm_container_registry" "example" {
#   name                = "containerRegistry1"
#   resource_group_name = azurerm_resource_group.example.name
#   location            = azurerm_resource_group.example.location
#   sku                 = "Premium"
# }

# resource "azurerm_role_assignment" "example" {
#   principal_id                     = azurerm_kubernetes_cluster.k8s-cluster.kube
#   role_definition_name             = "AcrPull"
#   scope                            = azurerm_container_registry.example.id
#   skip_service_principal_aad_check = true
# }

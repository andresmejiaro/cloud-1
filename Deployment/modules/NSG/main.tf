resource "azurerm_network_security_group" "this" {
  name                = "NSG"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22","80","443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
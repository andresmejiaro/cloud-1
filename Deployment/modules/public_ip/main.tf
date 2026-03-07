resource "azurerm_public_ip" "this" {
  name                = "acceptanceTestPublicIp1"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}
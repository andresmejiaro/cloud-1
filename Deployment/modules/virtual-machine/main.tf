resource "azurerm_linux_virtual_machine" "this" {
  name                = "example-machine"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = "Standard_B2als_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    var.interface_id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
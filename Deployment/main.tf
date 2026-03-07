module "resource_group" {
    source = "./modules/resource_group"
    name = var.resource_group_name
    location =  var.location
}

module "virtual-network" {
    source = "./modules/virtual-network"
    name = var.virtual_network_name
    address_space = var.address_space
    location = var.location
    resource_group_name = module.resource_group.name
}

module "subnet" {
    source = "./modules/subnet"
    virtual_network_name = module.virtual-network.name
    resource_group_name = module.resource_group.name
}

module "public_ip" {
    source = "./modules/public_ip"
    location = var.location
    resource_group_name = module.resource_group.name 
}

module "network_interface" {
    source = "./modules/network-interface"
    location = var.location
    resource_group_name = module.resource_group.name
    subnet_id = module.subnet.id
    public_ip_address_id =  module.public_ip.id
}

module "virtual_machine" {
    source = "./modules/virtual-machine"
    location = var.location
    resource_group_name = module.resource_group.name
    interface_id = module.network_interface.id
}
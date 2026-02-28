variable "resource_group_name" {
    type = string
}

variable "location" {
    type = string
}

#variable "vm_name" {
#    type = string
#}

#variable "admin_username" {
#    type = string
#}

#variable "ssh_public_key" {
#    type = string
#}

variable "tags" {
    type = map(string)

    default = {
      "project" = "cloud-1"
    }
  
}

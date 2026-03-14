
variable "location" {
    type = string
}

variable "env" {
  type = string
}

variable "tags" {
    type = map(string)

    default = {
      "project" = "cloud-1"
    }
  
}


variable "address_space" {
    type = list(string)
}
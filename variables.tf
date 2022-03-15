# -- Variables --
# variable "subnets"{
# }
variable "prefix" {
  description = "For consistent system name for all resources"
  type = string
  default = "GitLab"
}
variable "admin_user" {
  description = "User name to use as the admin account on the VMs that will be part of the VM scale set"
  type = string
  default = "testadmin"
}
variable "admin_password" {
  type = string
  default = "12345678Qws!"
}
variable "resource_group_name" {
  #using ACG sandbox resource group
  type = string
  default = "1-38fbc41a-playground-sandbox"
}
variable "location" {
  type = string  
  default = "East US"
}
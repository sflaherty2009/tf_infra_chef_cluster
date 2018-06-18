variable "automate_package_name" {
    type = "string"
    description = "Name of Chef Automate Package to Install"
    default = "automate_1.8.3-1_amd64.deb"
}

variable "automate_package_url" {
    type = "string"
    description = "URL to download Chef Automate Package"
    default = "https://packages.chef.io/files/stable/automate/1.8.3/ubuntu/16.04/automate_1.8.3-1_amd64.deb"
}

variable "chef_server_package_name" {
    type = "string"
    description = "Name of Chef Server Package to Install"
    default = "chef-server-core_12.17.15-1_amd64.deb"
}

variable "chef_server_package_url" {
    type = "string"
    description = "URL to download Chef Server Package"
    default = "https://packages.chef.io/files/stable/chef-server/12.17.15/ubuntu/16.04/chef-server-core_12.17.15-1_amd64.deb"
}

variable "chefdk_package_name" {
    type = "string"
    description = "Name of ChefDK Package to Install"
    default = "chefdk_2.4.17-1_amd64.deb"
}

variable "chefdk_package_url" {
    type = "string"
    description = "URL to download ChefDK Package"
    default = "https://packages.chef.io/files/stable/chefdk/2.4.17/ubuntu/16.04/chefdk_2.4.17-1_amd64.deb"
}

variable "location" {
  default = "eastus2"
}

variable "subnet_id" {
    default = "/subscriptions/9fbf7025-df40-4908-b7fb-a3a2144cee91/resourceGroups/AZ-RG-Network/providers/Microsoft.Network/virtualNetworks/AZ-VN-EastUS2-02/subnets/AZ-SN-dvo"
}

variable "license_file" {
    type = "string"
    description = "Path to Chef Automate license file"
    default = "./delivery.license"
}
#instance settings 
variable "publisher" {
  default = "Canonical"
}
variable "offer" {
  default = "UbuntuServer"
}
variable "sku" {
  default = "16.04-LTS"
}
variable "version" {
  default = "latest"
}
variable "vm_size" {
  default = "Standard_A4_v2"
}
# CHEF
variable "chef_resource_group_name" {
  default = "AZL-ChefServer-02"
}
variable "chef_admin_password" {
  default = "ZyADTVd64swkdvfHFMeR"
}
variable "chef_admin_user" {
  default = "devops"
}
variable "chef_computer_name" {
  default = "azl-ChefServer-02"
}
# AUTOMATE 
variable "auto_resource_group_name" {
  default = "azl-AutoServer-01"
}
variable "auto_computer_name" {
  default = "azl-AutoServer-01"
}

locals {
  admin_credentials = "${split("\n",file("${path.module}/secrets/admin_credentials"))}"
  auto_admin_user = "${local.admin_credentials[0]}"
  auto_admin_password = "${local.admin_credentials[1]}"
}

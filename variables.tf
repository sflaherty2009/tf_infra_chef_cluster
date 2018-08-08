variable "location" {
  default = "eastus2"
}

variable "subnet_id" {
  default = "/subscriptions/9fbf7025-df40-4908-b7fb-a3a2144cee91/resourceGroups/AZ-RG-Network/providers/Microsoft.Network/virtualNetworks/AZ-VN-EastUS2-02/subnets/AZ-SN-dvo"
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

# CHEF SERVER
variable "chef_resource_group" {
  default = "AZ-RG-CHEF-SERVER"
}

variable "chef_vm_size" {
  default = "Standard_A4_v2"
}

variable "chef_computer_name" {
  default = "azl-chef-srvr-01"
}

variable "chef_server_package_name" {
  type        = "string"
  description = "Name of Chef Server Package to Install"
  default     = "chef-server-core_12.17.33-1_amd64.deb"
}

variable "chef_server_package_url" {
  type        = "string"
  description = "URL to download Chef Server Package"
  default     = "https://packages.chef.io/files/stable/chef-server/12.17.33/ubuntu/16.04/"
}

# AUTOMATE 
variable "auto_resource_group" {
  default = "AZ-RG-CHEF-AUTO"
}

variable "auto_computer_name" {
  default = "azl-chef-auto-01"
}

variable "auto_vm_size" {
  default = "Standard_D4_v3"
}

variable "automate_package_name" {
  type        = "string"
  description = "Name of Chef Automate Package to Install"
  default     = "automate_1.8.85-1_amd64.deb"
}

variable "automate_package_url" {
  type        = "string"
  description = "URL to download Chef Automate Package"
  default     = "https://packages.chef.io/files/stable/automate/1.8.85/ubuntu/16.04/"
}

# RUNNER(S)
variable "runner_resource_group" {
  default = "AZ-RG-CHEF-RUNNER"
}

variable "runner_count" {
  default = 3
}

variable "runner_vm_size" {
  default = "Standard_B2s"
}

variable "runner_computer_name" {
  default = "azl-chef-runr"
}

variable "runner_chefdk_version" {
  default = "3.1.0"
}

locals {
  admin_credentials       = "${split("\n",file("${path.module}/secrets/admin_credentials"))}"
  admin_user              = "${local.admin_credentials[0]}"
  admin_password          = "${local.admin_credentials[1]}"
  azure_storage           = "${split("\n",file("${path.module}/secrets/azure_storage"))}"
  azure_account_name      = "${local.azure_storage[0]}"
  azure_account_key       = "${local.azure_storage[1]}"
  azure_service_principal = "${local.azure_storage[2]}"
  azure_password          = "${local.azure_storage[3]}"
  azure_tenant_id         = "${local.azure_storage[4]}"
}

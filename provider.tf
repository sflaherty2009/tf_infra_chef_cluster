terraform {
  backend "azurerm" {
    storage_account_name = "terraformlock"
    container_name       = "environments"
    resource_group_name  = "dvo_terraform"
    key                  = "chef-automate/terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "9fbf7025-df40-4908-b7fb-a3a2144cee91"
}

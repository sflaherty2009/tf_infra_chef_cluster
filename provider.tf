terraform {
  backend "azurerm" {
    storage_account_name = "terraformlock"
    container_name       = "environments"
    resource_group_name  = "dvo_terraform"
    key                  = "chef-automate/terraform.tfstate"
  }
   required_providers {
      azurerm = {
         subscription_id = "xxxx"
         client_id = "xxxx"
         client_secret = "xxxx"
         tenant_id = "xxxx"
      }
   }
}

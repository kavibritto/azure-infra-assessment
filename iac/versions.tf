terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.42.0"
    }
  }

  backend "azurerm" {
    tenant_id = "5560a310-6249-441c-a7a8-22324a8b8ce4"
    resource_group_name  = "rg-tfstates"
    storage_account_name = "st24951tfstatekavi"   # or your SA from step 1
    container_name       = "tfstate"
    key                  = "platform/terraform.tfstate"
    
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = "267bb7a7-50eb-4c5b-81ee-4adc1b915849"
  features {

  }
}


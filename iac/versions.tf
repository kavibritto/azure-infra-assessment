terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.42.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  subscription_id = "267bb7a7-50eb-4c5b-81ee-4adc1b915849"
  features {

  }
}
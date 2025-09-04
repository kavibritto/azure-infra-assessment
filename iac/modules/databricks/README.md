# Azure Databricks Workspace (VNet-injected)

This module provisions an Azure Databricks Workspace with custom VNet injection for private network control.

## Features

- ✅ VNet injection (public/private subnets)
- ✅ No public IP
- ✅ Reusable with cluster modules

## Usage

```hcl
module "databricks_workspace" {
  source               = "./modules/databricks-workspace"
  prefix               = "sandbox"
  location             = "East US"
  resource_group_name  = "rg-sandbox"
  vnet_id              = azurerm_virtual_network.this.id
  public_subnet_name   = "subnet-public"
  private_subnet_name  = "subnet-private"
}
```
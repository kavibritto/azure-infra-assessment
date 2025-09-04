# Versions
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.42.0"
    }
  }
}

# ------------------------
# Resource Group
# ------------------------
resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}
# ------------------------
# Hub VNet
# ------------------------
resource "azurerm_virtual_network" "this" {
  name                = "${var.prefix}-vnet"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

# ------------------------
# Subnets (map of objects)
# ------------------------
resource "azurerm_subnet" "this" {
  for_each             = var.subnets
  name                 = each.key
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [each.value]
}

# ------------------------
# Route Table
# ------------------------
resource "azurerm_route_table" "this" {
  name                = "${var.prefix}-rt"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

# Routes
# resource "azurerm_route" "route" {
#   name                   = "DefaultRoute"
#   resource_group_name    = var.resource_group_name
#   route_table_name       = azurerm_route_table.this.name
#   address_prefix         = "0.0.0.0/0" # Demo purpose 
#   next_hop_type          = "Internet"
#   next_hop_in_ip_address = null
# }

# ------------------------
# Route Table Association
# ------------------------
resource "azurerm_subnet_route_table_association" "this" {
  for_each       = var.subnets
  subnet_id      = azurerm_subnet.this[each.key].id
  route_table_id = azurerm_route_table.this.id
}

resource "azurerm_public_ip" "nat_pip" {
  count                   = var.enable_nat ? 1 : 0
  name                    = "${var.prefix}-natpip"
  location                = var.location
  resource_group_name     = var.resource_group_name
  allocation_method       = "Static"
  sku                     = "Standard"
  idle_timeout_in_minutes = 15
  tags                    = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count                   = var.enable_nat ? 1 : 0
  name                    = "${var.prefix}-natgw"
  location                = var.location
  resource_group_name     = var.resource_group_name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "pip_assoc" {
  count                = var.enable_nat ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat_pip[0].id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_assoc" {
  for_each       = var.enable_nat ? var.subnets : {}
  subnet_id      = azurerm_subnet.this[each.key].id
  nat_gateway_id = azurerm_nat_gateway.this[0].id

}

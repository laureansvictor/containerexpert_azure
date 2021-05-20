resource "azurerm_resource_group" "vnet" {
  name     = "${upper(var.environment)}${var.resource_prefix}Vnet-RG"
  location = var.location
  tags = {
    application = var.resource_prefix
    environment = var.environment
    managedBy   = "terraform"
    role        = "vnet"
  }
}

module "vnet" {
  source              = "Azure/vnet/azurerm"
  vnet_name           = "${upper(var.environment)}${var.resource_prefix}Vnet"
  resource_group_name = azurerm_resource_group.vnet.name
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24"]
  subnet_names        = ["dockerMaster"]

  tags = azurerm_resource_group.vnet.tags

  depends_on = [azurerm_resource_group.vnet]
}
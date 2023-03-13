# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#---------------------------------------------------------
# Private Link for Storage Account - Default is "false" 
#---------------------------------------------------------
data "azurerm_virtual_network" "vnet" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = var.virtual_network_name
  resource_group_name = local.resource_group_name
}

data "azurerm_subnet" "existing_snet" {
  count                = var.create_private_endpoint_subnet == false ? 1 : 0
  name                 = var.existing_private_subnet_name
  resource_group_name  = local.resource_group_name
  virtual_network_name = var.virtual_network_name
}

resource "azurerm_subnet" "snet_pep" {
  count                                     = var.create_private_endpoint_subnet && var.enable_private_endpoint ? 1 : 0
  name                                      = "snet-private-endpoint-${var.workload_name}-${local.location}"
  resource_group_name                       = local.resource_group_name
  virtual_network_name                      = data.azurerm_virtual_network.vnet.0.name
  address_prefixes                          = var.private_subnet_address_prefix
  private_endpoint_network_policies_enabled = true
}

resource "azurerm_private_endpoint" "pep" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = format("%s-private-endpoint", local.container_name)
  location            = var.location
  resource_group_name = local.resource_group_name
  subnet_id           = var.create_private_endpoint_subnet ? azurerm_subnet.snet_pep.0.id : data.azurerm_subnet.existing_snet.0.id
  tags                = merge({ "Name" = format("%s-private-endpoint", local.container_name) }, var.add_tags, )

  private_dns_zone_group {
    name                 = "container-registry-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.0.id]
  }

  private_service_connection {
    name                           = "containerregistry-privatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_container_registry.container_registry.id
    subresource_names              = ["registry"]
  }
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count               = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                = var.environment == "public" ? "privatelink.azurecr.io" : "privatelink.azurecr.us"
  resource_group_name = local.resource_group_name
  tags                = merge({ "Name" = format("%s", "Azure-Container-Registry-Private-DNS-Zone") }, var.add_tags, )
}

resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  count                 = var.existing_private_dns_zone == null && var.enable_private_endpoint ? 1 : 0
  name                  = "vnet-private-zone-link"
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dns_zone.0.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.0.id
  tags                  = merge({ "Name" = format("%s", "vnet-private-zone-link") }, var.add_tags, )
}

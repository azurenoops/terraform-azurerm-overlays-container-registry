# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#-------------------------------------
# VNET Creation - Default is "true"
#-------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "acr-vnet"
  location            = module.mod_azure_region_lookup.location_cli
  resource_group_name = "anoa-eus-dev-acr-dev-rg"
  address_space       = ["10.0.100.0/24"]
}

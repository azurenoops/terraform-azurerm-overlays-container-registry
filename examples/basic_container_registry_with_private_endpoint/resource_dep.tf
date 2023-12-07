# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#-------------------------------------
# VNET Creation - Default is "true"
#-------------------------------------
# This module is used to lookup the Azure Region based on the Azure Region Name
module "mod_azure_region_lookup" {
  source  = "azurenoops/overlays-azregions-lookup/azurerm"
  version = "~> 1.0.0"

  azure_region = "usgovvirginia"
  
}

resource "azurerm_resource_group" "rg" {
  name     = "anoa-eus-dev-acr-dev-rg"
  location = module.mod_azure_region_lookup.location_cli
}

resource "azurerm_virtual_network" "vnet" {
  name                = "acr-vnet"
  location            = module.mod_azure_region_lookup.location_cli
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}


resource "azurerm_subnet" "subnet" {
  name                 = "acr-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.100.0/24"]
  private_endpoint_network_policies_enabled = false
}
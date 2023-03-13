# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

#------------------------------------------------------------------
# Azure Container Registry Lock configuration - Default (required). 
#------------------------------------------------------------------
resource "azurerm_management_lock" "storage_account_level_lock" {
  count      = var.enable_resource_locks ? 1 : 0
  name       = "${local.container_name}-${var.lock_level}-lock"
  scope      = azurerm_container_registry.container_registry.id
  lock_level = var.lock_level
  notes      = "Azure Container Registry '${local.container_name}' is locked with '${var.lock_level}' level."
}

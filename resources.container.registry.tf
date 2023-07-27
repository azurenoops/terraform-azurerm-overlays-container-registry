# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

resource "azurerm_container_registry" "container_registry" {
  name = local.container_name

  location            = local.location
  resource_group_name = local.resource_group_name
  sku                 = var.sku
  admin_enabled       = var.admin_enabled

  public_network_access_enabled = var.public_network_access_enabled
  network_rule_bypass_option    = var.azure_services_bypass_allowed ? "AzureServices" : "None"

  data_endpoint_enabled = var.data_endpoint_enabled

  dynamic "retention_policy" {
    for_each = var.images_retention_enabled && var.sku == "Premium" ? ["enabled"] : []

    content {
      enabled = var.images_retention_enabled
      days    = var.images_retention_days
    }
  }

  dynamic "trust_policy" {
    for_each = var.trust_policy_enabled && var.sku == "Premium" ? ["enabled"] : []

    content {
      enabled = var.trust_policy_enabled
    }
  }

  dynamic "georeplications" {
    for_each = var.georeplications != null && var.sku == "Premium" ? var.georeplications : []

    content {
      location                  = try(georeplications.value.location, georeplications.value)
      zone_redundancy_enabled   = try(georeplications.value.zone_redundancy_enabled, null)
      regional_endpoint_enabled = try(georeplications.value.regional_endpoint_enabled, null)
      tags                      = merge({ "Name" = format("%s", "georep-acr-${georeplications.value.location}") }, var.add_tags, )
    }
  }

  dynamic "network_rule_set" {
    for_each = var.network_rule_set != null ? [var.network_rule_set] : []
    content {
      default_action = lookup(network_rule_set.value, "default_action", "Allow")

      dynamic "ip_rule" {
        for_each = network_rule_set.value.ip_rule
        content {
          action   = "Allow"
          ip_range = ip_rule.value.ip_range
        }
      }

      dynamic "virtual_network" {
        for_each = network_rule_set.value.virtual_network
        content {
          action    = "Allow"
          subnet_id = virtual_network.value.subnet_id
        }
      }
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_policy != null ? [var.retention_policy] : []
    content {
      days    = lookup(retention_policy.value, "days", 7)
      enabled = lookup(retention_policy.value, "enabled", true)
    }
  }

  dynamic "trust_policy" {
    for_each = var.enable_content_trust ? [1] : []
    content {
      enabled = var.enable_content_trust
    }
  }

  identity {
    type         = var.identity_ids != null ? "SystemAssigned, UserAssigned" : "SystemAssigned"
    identity_ids = var.identity_ids
  }

  dynamic "encryption" {
    for_each = var.encryption != null ? [var.encryption] : []
    content {
      enabled            = true
      key_vault_key_id   = encryption.value.key_vault_key_id
      identity_client_id = encryption.value.identity_client_id
    }
  }

  tags = merge(local.default_tags, var.add_tags)

  lifecycle {
    precondition {
      condition     = !var.data_endpoint_enabled || var.sku == "Premium"
      error_message = "Premium SKU is mandatory to enable the data endpoints."
    }
  }
}

#------------------------------------------------------------
# Container Registry Resoruce Scope map - Default is "false"
#------------------------------------------------------------

resource "azurerm_container_registry_scope_map" "main" {
  for_each                = var.scope_map != null ? { for k, v in var.scope_map : k => v if v != null } : {}
  name                    = format("%s", each.key)
  resource_group_name     = local.resource_group_name
  container_registry_name = azurerm_container_registry.container_registry.name
  actions                 = each.value["actions"]
}

#------------------------------------------------------------
# Container Registry Token  - Default is "false"
#------------------------------------------------------------
resource "azurerm_container_registry_token" "main" {
  for_each                = var.scope_map != null ? { for k, v in var.scope_map : k => v if v != null } : {}
  name                    = format("%s", "${each.key}-token")
  resource_group_name     = local.resource_group_name
  container_registry_name = azurerm_container_registry.container_registry.name
  scope_map_id            = element([for k in azurerm_container_registry_scope_map.main : k.id], 0)
  enabled                 = true
}

#------------------------------------------------------------
# Container Registry webhook - Default is "true"
#------------------------------------------------------------
resource "azurerm_container_registry_webhook" "main" {
  for_each            = var.container_registry_webhooks != null ? { for k, v in var.container_registry_webhooks : k => v if v != null } : {}
  name                = format("%s", each.key)
  resource_group_name = local.resource_group_name
  location            = local.location
  registry_name       = azurerm_container_registry.container_registry.name
  service_uri         = each.value["service_uri"]
  actions             = each.value["actions"]
  status              = each.value["status"]
  scope               = each.value["scope"]
  custom_headers      = each.value["custom_headers"]
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

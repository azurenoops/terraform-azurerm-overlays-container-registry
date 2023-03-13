output "container_registry_id" {
  description = "The Container Registry ID."
  value       = azurerm_container_registry.container_registry.id
}

output "container_registry_name" {
  description = "The Container Registry name."
  value       = azurerm_container_registry.container_registry.name
}

output "login_server" {
  description = "The URL that can be used to log into the container registry."
  value       = azurerm_container_registry.container_registry.login_server
}

output "container_registry_fqdn" {
  description = "The Container Registry FQDN."
  value       = azurerm_container_registry.container_registry.login_server
}

output "admin_username" {
  description = "The Username associated with the Container Registry Admin account - if the admin account is enabled."
  value       = azurerm_container_registry.container_registry.admin_username
}

output "admin_password" {
  description = "The Password associated with the Container Registry Admin account - if the admin account is enabled."
  value       = azurerm_container_registry.container_registry.admin_password
  sensitive   = true
}
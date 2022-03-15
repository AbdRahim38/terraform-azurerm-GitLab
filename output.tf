output "public_ip_address" {
  description = "[Public IP Address]"
  value       = azurerm_public_ip.main.ip_address
}

output "domain_name_label" {
  description = "[FQDN]"
  value       = azurerm_public_ip.main.*.fqdn
}

output "ssh_command" {
  description = "[SSH Command]"
  value       = "ssh testadmin@${azurerm_public_ip.main.ip_address}"
}


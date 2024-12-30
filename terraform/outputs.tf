output "web_public_ips" {
  value = module.compute.external_ips
}

output "database_endpoint" {
  value = module.database.db_address
}

output "database_port" {
  value = module.database.db_port
}
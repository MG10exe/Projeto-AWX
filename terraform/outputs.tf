output "web_public_ips" {
  value = [for instance in google_compute_instance.web : instance.network_interface[0].access_config[0].nat_ip]
}

output "database_endpoint" {
  value = google_sql_database_instance.database.private_ip_address
}

output "database_port" {
  value = 3306
}

output "vpc_id" {
  value = google_compute_network.vpc.id
}

output "public_subnets_ids" {
  value = [for sub in google_compute_subnetwork.public : sub.id]
}

output "private_subnets_ids" {
  value = [for sub in google_compute_subnetwork.private : sub.id]
}
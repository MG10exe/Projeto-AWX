output "external_ips" {
  value = [for instance in google_compute_instance.web : instance.network_interface[0].access_config[0].nat_ip]
}

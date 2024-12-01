resource "google_compute_firewall" "acesso_geral" {
  name        = "acesso-geral"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server", "https-server"]
}
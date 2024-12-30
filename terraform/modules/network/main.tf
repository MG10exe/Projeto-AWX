resource "google_compute_network" "vpc" {
  name                    = "tutorial-vpc"
  auto_create_subnetworks = false # Desabilita a criação automática de sub-redes
}

resource "google_compute_subnetwork" "public" {
  count = length(var.public_subnet_cidr_blocks)
  name          = "tutorial-public-subnet-${count.index}"
  ip_cidr_range = var.public_subnet_cidr_blocks[count.index]
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "private" {
  count = length(var.private_subnet_cidr_blocks)
  name          = "tutorial-private-subnet-${count.index}"
  ip_cidr_range = var.private_subnet_cidr_blocks[count.index]
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_router" "router" {
  name    = "tutorial-router"
  region  = var.region
  network = google_compute_network.vpc.name
}

resource "google_compute_router_nat" "nat" {
  name                  = "tutorial-nat"
  router                = google_compute_router.router.name
  region                = var.region
  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  depends_on = [google_compute_router.router]
}
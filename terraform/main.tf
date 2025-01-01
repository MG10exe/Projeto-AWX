terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.12.0"
    }
  }
  backend "gcs" {
    bucket  = "my-terraform-state"
    prefix  = "terraform/state"
    project = var.gcp_project
  }
}

provider "google" {
  credentials = var.gcp_credentials_path
  project     = var.gcp_project
  region      = var.region
}

data "google_secret_manager_secret_version" "chave_publica" {
  secret  = "chave-publica-awxServer"
  project = var.gcp_project
}

# Rede (VPC e Sub-redes)
resource "google_compute_network" "vpc" {
  name                    = "tutorial-vpc"
  auto_create_subnetworks = false
}

resource "google_service_networking_connection" "service_networking" {
  network              = google_compute_network.vpc.id
  service              = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_address.service_networking_ip.name]

  depends_on = [google_compute_network.vpc]
}

resource "google_compute_address" "service_networking_ip" {
  name          = "service-networking-ip"
  region        = var.region
  address_type  = "INTERNAL"
  address       = "10.10.0.1"
}

# Sub-rede Pública
resource "google_compute_subnetwork" "public" {
  count         = length(var.public_subnet_cidr_blocks)
  name          = "tutorial-public-subnet-${count.index}"
  ip_cidr_range = var.public_subnet_cidr_blocks[count.index]
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Sub-rede Privada
resource "google_compute_subnetwork" "private" {
  count         = length(var.private_subnet_cidr_blocks)
  name          = "tutorial-private-subnet-${count.index}"
  ip_cidr_range = var.private_subnet_cidr_blocks[count.index]
  region        = var.region
  network       = google_compute_network.vpc.id
}

# Compute (Instâncias e Firewall)
resource "google_compute_instance" "web" {
  count         = var.compute_settings.count
  name          = "tutorial-web-${terraform.workspace}-${count.index}"
  machine_type  = var.compute_settings.machine_type
  zone          = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "projects/${var.compute_settings.source_image_project}/global/images/family/${var.compute_settings.source_image_family}"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public[0].id
    access_config {}
  }

  metadata = {
    ssh-keys = "matheusgandrade:${data.google_secret_manager_secret_version.chave_publica.secret_data}"
    }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  // source_ranges = ["${var.my_ip}/32"]
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_db" {
  name    = "allow-db"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
  source_ranges = [google_compute_subnetwork.public[0].ip_cidr_range]
}

# Rota para Gateway de Internet na sub-rede pública
resource "google_compute_router" "internet_gateway" {
  name    = "tutorial-router"
  network = google_compute_network.vpc.id
  region  = var.region
}

resource "google_compute_router_nat" "nat" {
  name                                 = "nat-${google_compute_subnetwork.public[0].name}"
  router                               = google_compute_router.internet_gateway.name
  region                               = var.region
  nat_ip_allocate_option               = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat   = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.public[0].name
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

# Banco de Dados
resource "google_sql_database_instance" "database" {
  name             = "tutorial-database"
  region           = var.region
  database_version = var.db_settings.engine_version

  settings {
    tier = var.db_settings.tier
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc.id
    }
  }

  deletion_protection = var.db_settings.deletion_protection

}

resource "google_sql_database" "database" {
  name     = var.db_settings.database_name
  instance = google_sql_database_instance.database.name
}

resource "google_sql_user" "users" {
  name     = var.db_settings.root_username
  instance = google_sql_database_instance.database.name
  password = var.db_settings.root_password
}

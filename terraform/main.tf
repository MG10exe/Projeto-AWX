terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.12.0"
    }
  }
  backend "gcs" {}
}

provider "google" {
  credentials = var.gcp_credentials_path
  project     = var.gcp_project
  region      = var.region
}

data "google_secret_manager_secret_version" "chave_publica" {
  secret  = "chave-publica-servidor-awx"
  project = var.gcp_project
}

# Rede (VPC e Sub-redes)
resource "google_compute_network" "vpc" {
  name                    = "tutorial-vpc"
  auto_create_subnetworks = false
  routing_mode = "GLOBAL"
}

resource "google_compute_subnetwork" "default" {
  name          = "my-subnet"
  ip_cidr_range = "10.1.0.0/16"
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_address" "internal_with_subnet_and_address" {
  name         = "my-internal-address"
  subnetwork   = google_compute_subnetwork.default.id
  address_type = "INTERNAL"
  address      = "10.1.0.10"
  region       = var.region
}

# Create an IP address
resource "google_compute_global_address" "private_ip_alloc" {
  name          = "private-ip-alloc"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc.id

  depends_on = [google_service_networking_connection.default]
}

# Create a private connection
resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_alloc.name]

  depends_on = [google_compute_global_address.private_ip_alloc]

}

# Sub-rede Pública
resource "google_compute_subnetwork" "public" {
  count         = length(var.public_subnet_cidr_blocks)
  name          = "tutorial-public-subnet-${count.index}"
  ip_cidr_range = var.public_subnet_cidr_blocks[count.index]
  region        = var.region
  network       = google_compute_network.vpc.id
}

resource "google_compute_route" "default_internet_gateway" {
  name       = "default-route-public"
  network    = google_compute_network.vpc.id
  dest_range = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
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
    ssh-keys = "root:${data.google_secret_manager_secret_version.chave_publica.secret_data}"
    }
  
  tags = ["web-server"]
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

  depends_on = [
    google_service_networking_connection.default
  ]
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

resource "google_dns_managed_zone" "private_zone" {
  name        = "private-dns-zone"
  dns_name    = "internal."
  description = "Zona DNS privada para o banco de dados"
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.vpc.id
    }
  }
}

resource "google_dns_record_set" "db_dns" {
  name         = "database.internal."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.private_zone.name

  rrdatas = [google_sql_database_instance.database.private_ip_address]
}

terraform {
  required_providers {

    google = {
      source = "hashicorp/google"
      version = "5.12.0"
    }
  }

  backend "gcs" {}
}

provider "google" {
  credentials = var.gcp_credentials_path
  project = var.gcp_project
  region = var.gcp_region
}

# Criar VPC
resource "google_compute_network" "main_network" {
  name       = "tutorial-vpc"
  auto_create_subnetworks = false
}

# Subnets Públicas
resource "google_compute_subnetwork" "public_subnet" {
  name          = "public-subnet"
  ip_cidr_range = var.public_subnet_cidr_blocks[0]
  region        = var.gcp_region
  network       = google_compute_network.main_network.id
}

# Subnets Privadas
resource "google_compute_subnetwork" "private_subnets" {
  count         = var.subnet_count.private
  name          = "private-subnet-${count.index}"
  ip_cidr_range = var.private_subnet_cidr_blocks[count.index]
  region        = var.gcp_region
  network       = google_compute_network.main_network.id
}

# Regras de firewall para HTTP e SSH
resource "google_compute_firewall" "web_firewall" {
  name    = "web-firewall"
  network = google_compute_network.main_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Firewall para Cloud SQL
resource "google_compute_firewall" "sql_firewall" {
  name    = "sql-firewall"
  network = google_compute_network.main_network.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  source_tags = ["web-server"]
}

# Instância de Cloud SQL
resource "google_sql_database_instance" "main_sql" {
  name             = var.settings.database.instance_name
  region           = var.gcp_region
  database_version = var.settings.database.database_version

  settings {
    tier      = var.settings.database.tier
    disk_size = var.settings.database.storage_gb
    ip_configuration {
      require_ssl = false
  }

    backup_configuration {
      enabled = var.settings.database.backup_configuration
    }
  }
}

# Usuário do banco de dados
resource "google_sql_user" "main_user" {
  name     = var.db_username
  instance = google_sql_database_instance.main_sql.name
  password = var.db_password
}

# Instâncias Compute Engine
resource "google_compute_instance" "web_server" {
  count        = var.settings.web_app.count
  name         = "web-server-${count.index}"
  machine_type = var.settings.web_app.machine_type
  zone         = "${var.gcp_region}-a"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public_subnet.id
    access_config {}
  }

  tags = ["web-server"]
}

data "google_compute_image" "ubuntu" {
  family  = var.settings.web_app.image_family
  project = var.settings.web_app.image_project
}

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
  region = "us-east-1"
}

resource "google_compute_instance" "maquina_teste" {
  name = "maquina-teste"
  machine_type = var.instance_type["medium"]
  zone = "us-central1-c"

  boot_disk {
    initialize_params {
      image = "debian-11-bullseye-v20240110"
      labels = {
        my_label = "value"
      }
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  tags = ["http-server", "https-server"]
}
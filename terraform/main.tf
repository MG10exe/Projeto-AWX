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

data "google_secret_manager_secret_version" "chave_publica" {
  secret  = "chave-publica-awxServer"
  project = var.gcp_project
}

resource "google_compute_instance" "maquina_teste" {
  name = "maquina-teste"
  machine_type = var.instance_type["medium"]
  zone = "us-central1-c"

  metadata = {
    ssh-keys = "matheusgandrade:${data.google_secret_manager_secret_version.chave_publica.secret_data}"
    }

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

  tags = [
    "http-server",
    "https-server",
    "PublicIP=${google_compute_instance.maquina_teste.network_interface[0].access_config[0].nat_ip}"
  ]

  output "instance_public_ip" {
    value = aws_instance.example.public_ip
  }

}

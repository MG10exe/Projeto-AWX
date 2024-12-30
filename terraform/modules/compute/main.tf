resource "google_compute_instance" "web" {
  count         = var.compute_settings.count
  name          = "tutorial-web-${count.index}"
  machine_type  = var.compute_settings.machine_type
  zone          = "${var.region}-a"
  boot_disk {
    initialize_params {
        image = "projects/${var.compute_settings.source_image_project}/global/images/family/${var.compute_settings.source_image_family}"
    }
  }
  network_interface {
    subnetwork = var.public_subnets_ids[0]
    access_config {}
  }

  metadata = {
    ssh-keys = "matheusgandrade:${var.ssh_public_key}"
    }
}

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = var.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["${var.my_ip}/32"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http"
  network = var.vpc_id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_db" {
  name    = "allow-db"
  network = var.vpc_id
  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }
   source_ranges = ["10.0.0.0/16"]
}

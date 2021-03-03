# Terraform scripts - red team infrastructure
# author: Yael | @zkvL7
#
# annatar v1.0
# 

# Connection to GCP
provider "google" {
  credentials = file(var.credentials_file)
  project = var.project
  region  = var.region
  zone    = var.zone
}

# Static IP Address configuration
resource "google_compute_address" "static" {
  name = "${var.instance_name}-ipv4"
}

# Firewall rules for hosting services
resource "google_compute_firewall" "default" {
  name    = "${var.instance_name}-fw"
  network = google_compute_network.default.name
  target_tags = ["${var.instance_name}-fw"]
  
  allow {
    protocol = "tcp"
    ports    = var.open_ports
  }
}

# Network declaration
resource "google_compute_network" "default" {
  name = "${var.instance_name}-net"
}

# Instance creation
resource "google_compute_instance" "default" {
  name = var.instance_name
  hostname = var.hostname
  machine_type = "f1-micro"
  description = "${var.instance_name} vm machine"

  depends_on = [
    google_compute_network.default,
    google_compute_firewall.default,
  ]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  network_interface {
    network = "${var.instance_name}-net"
    access_config {
        nat_ip = "${google_compute_address.static.address}"
    }
  }

  tags = ["${var.instance_name}-fw"]

  # Add ssh key to login
  metadata = {
    ssh-keys = "${var.username}:${file(var.ssh_pubKey)}"
  }
}

# Instance external IP
output "external-ip" {
  value = "${google_compute_address.static.address}"
}
###############################
# Provider
###############################
provider "google" {
  project = var.gcp_project
  region  = var.gcp_region
  zone    = var.gcp_zone
}

###############################
# 1. VPC Network
###############################
resource "google_compute_network" "main" {
  name                    = "dev-vpc"
  auto_create_subnetworks = false
}

###############################
# 2. Subnet (with Flow Logs)
###############################
resource "google_compute_subnetwork" "main" {
  name          = "dev-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.main.id

  log_config {
    aggregation_interval = "INTERVAL_1_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

###############################
# 3. Internet Route
###############################
resource "google_compute_route" "default_internet" {
  name             = "default-internet-route"
  network          = google_compute_network.main.name
  dest_range       = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
}

###############################
# 4. Firewall (Allow SSH)
###############################
resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

###############################
# 5. SSH Key Pair
###############################
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

###############################
# 6. Compute Engine VM
###############################
resource "google_compute_instance" "vm" {
  name         = "crm-vm"
  machine_type = var.machine_type
  zone         = var.gcp_zone

  boot_disk {
    initialize_params {
      image = "${var.image_project}/${var.image_family}"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.id

    access_config {} # assigns external IP
  }

  metadata = {
    ssh-keys = "debian:${tls_private_key.example.public_key_openssh}"
  }

  tags = ["ssh"]
}

###############################
# 7. Local private key file
###############################
resource "local_file" "private_key" {
  content         = tls_private_key.example.private_key_pem
  filename        = "${path.module}/my-keypair.pem"
  file_permission = "0400"
}

###############################
# 8. Optional post-check
###############################
resource "null_resource" "post_setup" {
  provisioner "local-exec" {
    command = "echo VM deployed with SSH key saved locally"
  }

  depends_on = [
    google_compute_instance.vm,
    local_file.private_key
  ]
}

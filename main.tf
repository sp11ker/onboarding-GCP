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
# 2. Subnet
###############################
resource "google_compute_subnetwork" "main" {
  name          = "dev-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.gcp_region
  network       = google_compute_network.main.id
}

###############################
# 3. Route (Internet access)
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
# 5. Generate SSH Key Pair
###############################
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

###############################
# 6. Compute Instance
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

    access_config {} # gives external IP
  }

  metadata = {
    ssh-keys = "terraform:${tls_private_key.example.public_key_openssh}"
  }

  tags = ["ssh"]
}

###############################
# 7. Random suffix
###############################
resource "random_id" "suffix" {
  byte_length = 4
}

###############################
# 8. Storage Bucket (S3 equivalent)
###############################
resource "google_storage_bucket" "flow_logs_bucket" {
  name     = "my-flow-logs-bucket-${random_id.suffix.hex}"
  location = var.gcp_region

  uniform_bucket_level_access = true
}

###############################
# 9. Enable VPC Flow Logs (on subnet)
###############################
resource "google_compute_subnetwork" "main_with_logs" {
  name          = "dev-subnet-logs"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.gcp_region
  network       = google_compute_network.main.id

  log_config {
    aggregation_interval = "INTERVAL_1_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

###############################
# 10. Save private key locally
###############################
resource "local_file" "private_key_pem" {
  content         = tls_private_key.example.private_key_pem
  filename        = "${path.module}/my-keypair.pem"
  file_permission = "0600"
}

###############################
# 11. Post setup
###############################
resource "null_resource" "post_setup" {
  provisioner "local-exec" {
    command = "echo Private key saved at my-keypair.pem"
  }

  depends_on = [
    google_compute_instance.vm,
    local_file.private_key_pem
  ]
}

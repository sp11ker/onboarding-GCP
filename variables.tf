variable "gcp_project" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  default     = "europe-west2"
}

variable "gcp_zone" {
  description = "GCP zone"
  default     = "europe-west2-a"
}

variable "machine_type" {
  description = "VM machine type"
  default     = "e2-micro"
}

variable "image_family" {
  description = "GCP image family"
  default     = "debian-11"
}

variable "image_project" {
  description = "GCP image project"
  default     = "debian-cloud"
}

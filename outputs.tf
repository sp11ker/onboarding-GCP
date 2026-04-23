###############################
# Public IP of VM
###############################
output "instance_public_ip" {
  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

###############################
# Private Key (sensitive)
###############################
output "private_key_pem" {
  value     = tls_private_key.example.private_key_pem
  sensitive = true
}

###############################
# SSH Command (bonus)
###############################
output "ssh_command" {
  value = "ssh -i my-keypair.pem debian@${google_compute_instance.vm.network_interface[0].access_config[0].nat_ip}"
}

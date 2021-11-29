output "vm_ip" {
  value = google_compute_instance.default.network_interface.0.network_ip
}

output "name" {
  value = google_compute_instance.default.name
}

output "service_name" {
  value = google_cloud_run_service.service.name
}

output "service_location" {
  value = google_cloud_run_service.service.location
}

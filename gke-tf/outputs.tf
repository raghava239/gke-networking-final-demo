output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.gke_cluster.name
}

output "cluster_endpoint" {
  description = "The endpoint of the GKE cluster master"
  value       = google_container_cluster.gke_cluster.endpoint
}

output "network_name" {
  description = "The VPC network name created"
  value       = google_compute_network.gke_public_vpc.name
}

output "subnet_name" {
  description = "The subnet name created"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "gcloud_get_credentials" {
  description = "The gcloud command to configure kubectl credentials for the cluster"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.gke_cluster.name} --zone ${google_container_cluster.gke_cluster.location} --project ${var.project_id}"
}

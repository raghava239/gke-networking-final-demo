variable "project_id" {
  description = "The GCP Project ID where resources reside"
  type        = string
  default     = "raghupothula"
}

variable "region" {
  description = "The region where GKE and subnet reside"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "The zone where the GKE cluster node pool resides"
  type        = string
  default     = "us-central1-a"
}

locals {
  network_name     = "gke-public-vpc"
  subnetwork_name  = "gke-public-subnet"
  cluster_name     = "gke-public-cluster"
  node_pool_name   = "nodepool-1"
  machine_type     = "e2-medium"
}

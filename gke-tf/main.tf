provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "gke_public_vpc" {
  name                    = local.network_name
  auto_create_subnetworks = false
}

# Subnet with Secondary Ranges for Pods and Services
resource "google_compute_subnetwork" "gke_subnet" {
  name                     = local.subnetwork_name
  ip_cidr_range            = "10.10.10.0/24"
  region                   = var.region
  network                  = google_compute_network.gke_public_vpc.id
  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "gke-pods"
    ip_cidr_range = "10.20.10.0/24"
  }

  secondary_ip_range {
    range_name    = "gke-services"
    ip_cidr_range = "10.30.10.0/24"
  }
}

# Firewall rule: Allow all Ingress traffic
resource "google_compute_firewall" "allow_all_ingress" {
  name        = "gke-allow-all-ingress"
  network     = google_compute_network.gke_public_vpc.name
  direction   = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

# Firewall rule: Allow all Egress traffic
resource "google_compute_firewall" "allow_all_egress" {
  name        = "gke-allow-all-egress"
  network     = google_compute_network.gke_public_vpc.name
  direction   = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }
}

# GKE Cluster Definition
resource "google_container_cluster" "gke_cluster" {
  name     = local.cluster_name
  location = var.zone

  # Disable deletion protection for convenient cleanup in dev/test workspaces
  deletion_protection = false

  # We remove the default node pool to construct our own custom node pool.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.gke_public_vpc.id
  subnetwork = google_compute_subnetwork.gke_subnet.id

  # IP Allocation Policy for Pod/Service IP ranges (VPC-Native)
  ip_allocation_policy {
    cluster_secondary_range_name  = "gke-pods"
    services_secondary_range_name = "gke-services"
  }

  # Dataplane V2 configuration
  datapath_provider = "ADVANCED_DATAPATH"

  # GKE Addons Configuration
  addons_config {
    # Explicitly enable GKE's HTTP Load Balancing controller
    http_load_balancing {
      disabled = false
    }
  }

  # Enable Gateway API Controller
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }

  # Ensure the cluster is public
  private_cluster_config {
    enable_private_nodes    = false
    enable_private_endpoint = false
  }

  # Necessary for cluster-level configuration
  release_channel {
    channel = "REGULAR"
  }
}

# Custom Node Pool
resource "google_container_node_pool" "nodepool_1" {
  name       = local.node_pool_name
  location   = var.zone
  cluster    = google_container_cluster.gke_cluster.name
  node_count = 1

  node_config {
    machine_type = local.machine_type

    # Google Cloud recommended minimal scopes for standard VM instances in GKE
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

resource "google_container_cluster" "primary" {
  name     = "ecommerce-cluster"
  location = var.region

  # We manage node pools separately (below) instead of using the
  # default node pool, so we have full control over machine type/size/autoscaling.
  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Even though remove_default_node_pool = true, GKE briefly creates a
  # temporary default pool before deleting it. This node_config ensures
  # that temporary pool uses cheap pd-standard disks instead of SSD-backed
  # pd-balanced (the GCP default), avoiding SSD_TOTAL_GB quota errors on
  # free-tier/new projects.
  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
    disk_type    = "pd-standard"
  }

  deletion_protection = false
}

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }

  node_config {
    machine_type = "e2-medium"
    disk_size_gb = 20
    disk_type    = "pd-standard"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
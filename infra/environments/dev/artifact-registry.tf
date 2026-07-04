resource "google_artifact_registry_repository" "ecommerce_repo" {
  location      = var.region
  repository_id = "ecommerce-images"
  description   = "Docker images for ecommerce microservices"
  format        = "DOCKER"
}
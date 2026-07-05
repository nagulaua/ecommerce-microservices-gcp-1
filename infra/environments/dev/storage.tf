resource "google_storage_bucket" "product_images" {
  name          = "${var.project_id}-product-images"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}
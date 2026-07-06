resource "google_sql_database_instance" "postgres" {
  name             = "ecommerce-postgres"
  database_version = "POSTGRES_16"
  region           = var.region

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"

    database_flags {
      name  = "max_connections"
      value = "50"
    }

    ip_configuration {
      ipv4_enabled    = true
      authorized_networks {
        name  = "allow-all-dev"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled = true
    }
  
  }

  deletion_protection = false
}

resource "google_sql_database" "product_db" {
  name     = "productdb"
  instance = google_sql_database_instance.postgres.name
}

resource "google_sql_user" "app_user" {
  name     = "appuser"
  instance = google_sql_database_instance.postgres.name
  password = var.db_password
}

resource "google_secret_manager_secret" "db_password" {
  secret_id = "product-db-password"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}
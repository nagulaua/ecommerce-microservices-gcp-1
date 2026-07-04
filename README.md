# E-Commerce Microservices Platform (GCP)

Cloud-native e-commerce platform built on Google Cloud Platform.

## Stack
- **Compute**: GKE (Google Kubernetes Engine)
- **Database**: Cloud SQL
- **Messaging**: Pub/Sub
- **Storage**: Cloud Storage
- **IaC**: Terraform
- **CI/CD**: GitHub Actions + Artifact Registry
- **Observability**: Cloud Monitoring, Cloud Logging, Prometheus, Grafana
- **Security**: IAM, Secret Manager, RBAC, JWT

## Services
- user-service - authentication and user profiles
- product-service - product catalog and inventory
- order-service - order placement and event publishing
- notification-service - async notifications via Pub/Sub

## Structure
See infra/, services/, k8s/, and .github/workflows/ for infrastructure, application code, Kubernetes manifests, and CI/CD respectively.
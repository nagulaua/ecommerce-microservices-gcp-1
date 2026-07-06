# E-Commerce Microservices Platform

A cloud-native e-commerce platform deploying containerized Spring Boot microservices to Google Kubernetes Engine (GCP), with all infrastructure provisioned as code via Terraform. The project automates everything from cluster provisioning to secrets management, autoscaling, and event-driven service communication.

## Features

**Infrastructure (GCP)**

* Compute: Provisions a GKE cluster with an autoscaling node pool (1-3 `e2-medium` nodes, VPC-native networking, Workload Identity enabled)
* Networking: Dedicated VPC with secondary IP ranges for Pods and Services
* Secret Management: Uses GCP Secret Manager for database credentials, injected into workloads as Kubernetes Secrets
* Artifact Registry: Private Docker repository for all 4 service images
* Database: Managed Cloud SQL (Postgres 16) instance, database, and dedicated app user
* Messaging: Pub/Sub topic and subscription for event-driven order processing
* Storage: GCS bucket for product image assets
* IAM: Least-privilege role bindings for GKE node service accounts (Artifact Registry, Pub/Sub access)

**Application Services**

* `product-service` — product catalog CRUD, backed by Cloud SQL
* `user-service` — registration/login with JWT issuance, BCrypt password hashing
* `order-service` — order placement, publishes events to Pub/Sub
* `notification-service` — subscribes to order events for downstream notifications

**Kubernetes**

* Deployments with readiness/liveness probes backed by Spring Actuator health checks
* HorizontalPodAutoscaler (CPU-based, scales 1-6 replicas per service)
* ConfigMaps for non-secret config, Secrets for credentials
* RBAC policies scoping service account permissions to least-privilege

**CI/CD & Observability**

* GitHub Actions pipeline: builds, tags (by commit SHA), and pushes each service's image to Artifact Registry, then rolls out to GKE on every push to `main`
* Prometheus scrapes `/actuator/prometheus` on each service; Grafana visualizes the metrics

## Prerequisites

* Google Cloud SDK (`gcloud`) installed and authenticated
* A GCP project with billing enabled (Cloud SQL and GKE are not fully covered by the always-free tier)
* `kubectl`, `terraform`, `docker`, `java 17`, `maven` installed locally
* `gke-gcloud-auth-plugin` installed (`gcloud components install gke-gcloud-auth-plugin`)

## Getting Started

1. **Configure your environment**: set your GCP project ID and a database password.

```bash
cd infra/environments/dev
nano terraform.tfvars            # set project_id, region
nano terraform.tfvars.secret      # set db_password (never committed — see .gitignore)
```

2. **Provision infrastructure**:

```bash
terraform init
terraform apply -var-file="terraform.tfvars.secret"
```

3. **Connect kubectl to the new cluster**:

```bash
gcloud container clusters get-credentials ecommerce-cluster --region us-central1 --project <your-project-id>
```

4. **Build and push each service image**:

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev
cd ../../../services/product-service   # repeat per service
docker build -t us-central1-docker.pkg.dev/<project-id>/ecommerce-images/product-service:v1 .
docker push us-central1-docker.pkg.dev/<project-id>/ecommerce-images/product-service:v1
```

5. **Create the database secret and deploy**:

```bash
kubectl create secret generic product-db-secret --from-literal=DB_PASSWORD="$(gcloud secrets versions access latest --secret=product-db-password)"
kubectl apply -f k8s/base/product-service/
kubectl apply -f k8s/base/user-service/
kubectl apply -f k8s/base/order-service/
kubectl apply -f k8s/base/notification-service/
```

6. **Verify**:

```bash
kubectl get pods
kubectl port-forward svc/product-service 8080:80
curl http://localhost:8080/api/products
```

## Project Structure

* `services/` — Spring Boot source for each microservice (`product-service`, `user-service`, `order-service`, `notification-service`), each with its own `pom.xml`, `Dockerfile`, and `application.yml`
* `infra/` — Terraform IaC
  * `environments/dev/` — GKE, Cloud SQL, VPC, Pub/Sub, Storage, Secret Manager, Artifact Registry
  * `modules/` — reusable module scaffolding
* `k8s/base/` — Kubernetes manifests per service (Deployment, Service, ConfigMap, HPA) plus RBAC
* `monitoring/` — Prometheus and Grafana manifests
* `.github/workflows/` — CI/CD pipeline definition

## Verified Working

* `product-service` — full CRUD confirmed against live Cloud SQL, both internally and via public LoadBalancer
* `user-service` — registration and login confirmed end-to-end with a real signed JWT returned
* `order-service` — order placement confirmed end-to-end with correct pricing calculation and Cloud SQL persistence

## In Progress

* Pub/Sub delivery confirmation between `order-service` and `notification-service`
* First live run of the GitHub Actions CI/CD pipeline
* First live deployment of the Prometheus/Grafana stack

## Engineering Notes

Building this surfaced real infrastructure problems rather than following a scripted path: GCP disk/CPU quota limits on a free-tier project, IAM permission gaps between GKE nodes and both Artifact Registry and Pub/Sub, Kubernetes HPA silently overriding manual scaling commands, and Cloud SQL connection pool exhaustion when multiple replicas of a service connected to a `db-f1-micro` instance simultaneously.

## Cleanup

To tear down all GCP resources created by this project and stop billing:

```bash
kubectl delete -f k8s/base/product-service/service-external.yaml
cd infra/environments/dev
terraform destroy -var-file="terraform.tfvars.secret"
```

Local Docker images and all source code remain unaffected — infrastructure can be fully rebuilt from code with `terraform apply`.
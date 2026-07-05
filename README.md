# E-Commerce Microservices Platform (GCP)

A cloud-native e-commerce platform built with Spring Boot microservices, deployed on Google Kubernetes Engine (GKE), with infrastructure fully defined as code via Terraform.

## Architecture
                ┌─────────────────┐
                │  GitHub Actions │  (CI/CD)
                └────────┬────────┘
                         ▼
                ┌─────────────────┐
                │ Artifact Registry│
                └────────┬────────┘
                         ▼
    ┌────────────────────────────────────┐
    │              GKE Cluster            │
    │  ┌────────────┐  ┌────────────────┐│
    │  │product-svc │  │  user-service  ││
    │  │(Cloud SQL) │  │  (JWT auth)    ││
    │  └────────────┘  └────────────────┘│
    │  ┌────────────┐  ┌────────────────┐│
    │  │order-svc   │─▶│notification-svc││
    │  │(Pub/Sub    │  │(Pub/Sub        ││
    │  │ publisher) │  │ subscriber)    ││
    │  └────────────┘  └────────────────┘│
    └────────────────────────────────────┘
             │              │
      Cloud SQL      Secret Manager
    (managed Postgres)  (credentials)

## Services

| Service | Responsibility | Key Tech |
|---|---|---|
| `product-service` | Product catalog CRUD | Spring Boot, JPA, Cloud SQL |
| `user-service` | Registration, login, JWT issuance | Spring Security, BCrypt, JJWT |
| `order-service` | Order placement, publishes order events | Spring Cloud GCP Pub/Sub |
| `notification-service` | Consumes order events for notifications | Pub/Sub subscriber |

## Infrastructure (Terraform)

- **GKE** — autoscaling node pool (2–3 nodes), Workload Identity enabled
- **Cloud SQL** — managed Postgres 16
- **Artifact Registry** — private Docker image registry
- **Secret Manager** — database credentials, never hardcoded
- **VPC** — dedicated network with secondary ranges for Pods/Services

All infrastructure lives in [`infra/environments/dev`](infra/environments/dev) and is applied via `terraform apply`.

## Kubernetes

Each service ships with a Deployment (readiness/liveness probes), Service, ConfigMap, and HorizontalPodAutoscaler (CPU-based, 2–6 replicas). Manifests are in [`k8s/base`](k8s/base).

## Security

- Passwords hashed with BCrypt, never stored in plaintext
- Stateless JWT authentication (no server-side sessions)
- Database credentials sourced from GCP Secret Manager, injected via Kubernetes Secrets
- IAM least-privilege bindings for GKE node service accounts

## Status

`product-service` is fully deployed end-to-end on GKE: containerized, connected to live Cloud SQL, secrets sourced from Secret Manager, exposed via LoadBalancer, with autoscaling configured.

The remaining services (`user-service`, `order-service`, `notification-service`) have complete, tested, compiling code and Dockerfiles, ready for the same deployment pipeline.

## Roadmap

- [ ] Deploy remaining 3 services to GKE
- [ ] Provision Pub/Sub topics/subscriptions via Terraform
- [ ] GitHub Actions CI/CD (build → push → deploy)
- [ ] Prometheus + Grafana dashboards
- [ ] Cloud Monitoring + Logging integration
- [ ] Kubernetes RBAC policies
- [ ] Secret Manager CSI driver (replacing manual Secret sync)

## Running Locally

Each service can run standalone with Docker Compose (see `docker-compose.yml` in `product-service`) or against a local Postgres instance. See individual service `application.yml` for configuration.

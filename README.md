# E-Commerce Microservices Platform (GCP)

A cloud-native e-commerce platform built with Spring Boot microservices, deployed on Google Kubernetes Engine (GKE), with infrastructure fully defined as code via Terraform.

## Architecture
                ┌─────────────────┐
                │  GitHub Actions │  (CI/CD: build → push → deploy)
                └────────┬────────┘
                         ▼
                ┌─────────────────┐
                │ Artifact Registry│
                └────────┬────────┘
                         ▼
    ┌────────────────────────────────────┐
    │              GKE Cluster           │
    │  ┌────────────┐  ┌────────────────┐│
    │  │product-svc │  │  user-service  ││
    │  │(Cloud SQL) │  │  (JWT auth)    ││
    │  └────────────┘  └────────────────┘│
    │  ┌────────────┐  ┌────────────────┐│
    │  │order-svc   │─▶│notification-svc││
    │  │(Pub/Sub    │  │(Pub/Sub        ││
    │  │ publisher) │  │ subscriber)    ││
    │  └────────────┘  └────────────────┘│
    │  ┌────────────┐  ┌────────────────┐│
    │  │ Prometheus │─▶│    Grafana    ││
    │  └────────────┘  └────────────────┘│
    └────────────────────────────────────┘
             │              │
      Cloud SQL      Secret Manager
    (managed Postgres)  (credentials)

## Why I built this

I wanted hands-on experience with the full lifecycle of deploying microservices to a real cloud environment — not just writing Spring Boot APIs, but actually provisioning infrastructure, wiring up secrets properly, debugging IAM permission issues, and getting containers running reliably on Kubernetes under real constraints like GCP's free-tier quotas.

## Services

| Service | Responsibility | Key Tech |
|---|---|---|
| `product-service` | Product catalog CRUD | Spring Boot, JPA, Cloud SQL |
| `user-service` | Registration, login, JWT issuance | Spring Security, BCrypt, JJWT |
| `order-service` | Order placement, publishes order events | Spring Cloud GCP Pub/Sub |
| `notification-service` | Consumes order events for notifications | Pub/Sub subscriber |

## Infrastructure as Code (Terraform)

- **GKE** — autoscaling node pool, Workload Identity enabled, VPC-native networking
- **Cloud SQL** — managed Postgres 16
- **Pub/Sub** — topic + subscription for event-driven order processing
- **Cloud Storage** — bucket for product image assets
- **Artifact Registry** — private Docker image registry
- **Secret Manager** — database credentials, injected via Kubernetes Secrets, never hardcoded
- **VPC** — dedicated network with secondary IP ranges for Pods/Services

All infrastructure lives in [`infra/environments/dev`](infra/environments/dev) and is provisioned with a single `terraform apply`. I rebuild the environment on-demand from code (takes about 15-20 minutes) and tear it down between sessions to manage cloud costs.

## Kubernetes

Each service has a Deployment (with readiness/liveness probes backed by Spring Actuator), a Service, a ConfigMap, and a HorizontalPodAutoscaler. I added RBAC policies to scope service account permissions to least-privilege read access. Manifests are in [`k8s/base`](k8s/base).

## CI/CD

[`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) builds a Docker image per service, tags it with the commit SHA, pushes to Artifact Registry, and rolls out the update to GKE on every push to `main`.

## Observability

Prometheus scrapes each service's `/actuator/prometheus` endpoint (Micrometer-instrumented); Grafana visualizes what it collects. Manifests are in [`monitoring/`](monitoring).

## Security

- Passwords hashed with BCrypt — never stored in plaintext
- Stateless JWT authentication — no server-side session state, so it scales horizontally
- Database credentials sourced from GCP Secret Manager, injected as Kubernetes Secrets
- IAM least-privilege bindings for GKE node service accounts
- Kubernetes RBAC scoping in-cluster permissions

## Current status

All 4 services are containerized, pushed to Artifact Registry, and deployed to GKE, connected to a shared managed Cloud SQL instance, with secrets pulled from Secret Manager. I've verified `product-service` end-to-end multiple times — live CRUD operations against Cloud SQL, both from inside the cluster and through a public LoadBalancer.

The Pub/Sub flow between `order-service` and `notification-service`, and JWT issuance in `user-service`, are implemented and deployed — I'm still working through full end-to-end verification on those.

The Prometheus/Grafana stack and GitHub Actions CI/CD pipeline are complete.

## Some things I ran into building this

This Project I had to actually debug a handful of real infrastructure issues:

- GCP disk and CPU quota limits on a free-tier project, which meant tuning node pool disk types and pod resource requests to fit
- IAM permission gaps between GKE node service accounts and Artifact Registry that caused image pulls to fail with 403s
- Kubernetes' HPA `minReplicas` silently overriding manual `kubectl scale` commands
- Getting liveness/readiness probe timing right against actual JVM cold-start behavior once I tightened CPU limits — Spring Boot startup slowed to 60-80 seconds, which needed longer `initialDelaySeconds` than the defaults

## Running locally

Each service can run standalone against a local Postgres instance via Docker Compose (see `product-service/docker-compose.yml`). Config is externalized through `application.yml` and environment variables so the same image works locally, in CI, and in the cloud.

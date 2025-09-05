# Insight-Agent — GCP MVP (Cloud Run + Terraform + CI/CD)

**Goal:** Deploy a minimal Python analysis API (`POST /analyze`) as a secure, serverless, production-ready service on Google Cloud Platform. Everything is provisioned with **Terraform** and deployed by **GitHub Actions**.

---

## What you get in this repo

- `app/` — FastAPI application exposing `POST /analyze`.
- `Dockerfile` — Multi-stage, small image using `python:3.11-slim`, non-root user.
- `terraform/` — Complete Terraform configuration:
  - Optionally create a GCP Project (if you have billing and org permissions) or use an existing project (recommended).
  - Enable required APIs.
  - Create an Artifact Registry repo.
  - Create Cloud Run service with a dedicated runtime Service Account.
  - Create an "invoker" Service Account and grant it `roles/run.invoker` (so the service is **not** public).
- `.github/workflows/ci-cd.yml` — CI/CD pipeline (on push to `main`) that:
  1. Lints & tests the Python app.
  2. Builds and pushes the container image to Artifact Registry.
  3. Runs `terraform apply` passing the new image URI to update the Cloud Run service.

---

## Architecture (text diagram)

```
Developer (GitHub push)
        |
GitHub Actions (build & deploy)
        |
Artifact Registry  <-- Docker image pushed
        |
Terraform (applies image)
        |
Cloud Run (insight-agent)  -- runs with dedicated service account (no public invoker)
        ^
        |
Internal clients / authenticated callers (must use invoker service account or be allowed)
```

---

## Design Decisions

- **Cloud Run** — chosen for a serverless, autoscaling, managed platform that supports containers. It is easy to deploy via Terraform and integrates with Artifact Registry and IAM.
- **Security** — Cloud Run is configured **without** unauthenticated access. We create an `invoker` service account and bind `roles/run.invoker` to that SA. Only principals that explicitly authenticate as that SA (or are granted the role) can invoke the service.
- **CI/CD** — GitHub Actions authenticates to GCP using one of:
  - **Workload Identity Federation (recommended)** — short-lived credentials (no long-lived service account keys).
  - **Service account JSON** (fallback) — supply as GitHub secret `GCP_SA_KEY`.
  The workflow builds, pushes, and then runs Terraform with the new image URI.

---

## Quickstart (high level)

1. Create or choose a GCP project and enable billing.
2. Enable APIs (the Terraform config can enable them): Cloud Run, Artifact Registry, Cloud Build, IAM, Cloud Resource Manager.
3. Create a Service Account for GitHub Actions or configure Workload Identity Federation (recommended). Add it as a member with `roles/owner` for initial setup **(or** granular roles shown in README below).
4. Add GitHub Secrets:
   - `GCP_PROJECT_ID` (required)
   - `GCP_REGION` (e.g. `us-central1`) (required)
   - Either:
     - `WORKLOAD_ID_PROVIDER` and `GCP_SA_EMAIL` (for OIDC), **OR**
     - `GCP_SA_KEY` (service account JSON)
5. Push to `main`. The workflow will build, push, and deploy.

Full, step-by-step setup is in the `terraform/` folder README and the `README.md` inside that folder.

---

## Notes & Next steps

- To restrict ingress to your VPC (internal-only traffic), consider using a Serverless VPC Connector + Internal Load Balancer. The current setup prevents public unauthenticated access by removing public invoker permissions and granting invocation only to a specific service account.
- Logs and metrics are available via Cloud Logging & Cloud Monitoring.
- For production, lock down the GitHub Actions service account with least privilege (only grant what the workflow needs).

---


locals {
  project = var.project_id
}

# Optionally create a project (requires billing account and proper permissions)
resource "google_project" "project" {
  count      = var.create_project ? 1 : 0
  name       = "insight-agent-project"
  project_id = var.project_id
  billing_account = var.billing_account
}

# Enable required APIs
resource "google_project_service" "required" {
  for_each = toset([
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])
  project = local.project
  service = each.key
}

# Artifact Registry (Docker)
resource "google_artifact_registry_repository" "repo" {
  project       = local.project
  location      = var.region
  repository_id = var.artifact_repo
  description   = "Docker repository for Insight-Agent"
  format        = "DOCKER"
}

# Service Accounts
resource "google_service_account" "run_sa" {
  account_id   = "${var.service_name}-sa"
  display_name = "Cloud Run runtime service account"
  project      = local.project
}

resource "google_service_account" "invoker_sa" {
  account_id   = "${var.service_name}-invoker"
  display_name = "Service account allowed to invoke the Cloud Run service"
  project      = local.project
}

# Grant runtime SA permission to read images (Artifact Registry) and write logs/metrics
resource "google_project_iam_member" "run_sa_artifact" {
  project = local.project
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "run_sa_logging" {
  project = local.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

resource "google_project_iam_member" "run_sa_monitoring" {
  project = local.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.run_sa.email}"
}

# Cloud Run service
resource "google_cloud_run_service" "service" {
  name     = var.service_name
  location = var.region
  project  = local.project

  template {
    spec {
      service_account_name = google_service_account.run_sa.email

      containers {
        image = var.image
        ports {
          container_port = 8080
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true
}

# Prevent public unauthenticated access by giving run.invoker ONLY to invoker_sa
resource "google_cloud_run_service_iam_member" "invoker_binding" {
  location = google_cloud_run_service.service.location
  project  = google_cloud_run_service.service.project
  service  = google_cloud_run_service.service.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.invoker_sa.email}"

  depends_on = [google_cloud_run_service.service]
}

output "cloud_run_service" {
  value = google_cloud_run_service.service.name
}

output "invoker_service_account" {
  value = google_service_account.invoker_sa.email
}

output "runtime_service_account" {
  value = google_service_account.run_sa.email
}

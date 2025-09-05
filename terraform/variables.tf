variable "project_id" {
  description = "GCP project id to deploy to"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "artifact_repo" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "insight-agent-repo"
}

variable "service_name" {
  description = "Cloud Run service name"
  type        = string
  default     = "insight-agent"
}

variable "image" {
  description = "Container image URI to deploy to Cloud Run (pass from CI pipeline)"
  type        = string
  default     = ""
}

variable "create_project" {
  description = "Set to true to create a GCP Project (requires billing account)"
  type        = bool
  default     = false
}

variable "billing_account" {
  description = "Billing account id (only needed if create_project=true)"
  type        = string
  default     = ""
}

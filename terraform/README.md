# Terraform for Insight-Agent

This folder contains Terraform code that provisions:
- (Optionally) a GCP Project
- Enables required APIs
- Artifact Registry repository (Docker format)
- Service accounts for Cloud Run runtime and invoker
- Cloud Run service that uses the container image passed in via variable `image`

Usage:
1. Configure credentials so that `terraform` (and the GitHub Actions runner) can authenticate to GCP.
2. Run:
   ```
   terraform init
   terraform apply -var='project_id=your-project-id' -var='region=us-central1' -var='image=REGION-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG' -auto-approve
   ```

Notes:
- If you want Terraform to create the GCP project for you, set `create_project = true` and provide `billing_account`.
- The Cloud Run service is **not** granted public (unauthenticated) invoker rights. An `invoker` service account is created and given `roles/run.invoker`.

locals {
  services = [
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudscheduler.googleapis.com",
    "run.googleapis.com",
    "storage.googleapis.com",
    "workflows.googleapis.com",
    "iamcredentials.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "enable_apis" {
  for_each           = toset(local.services)
  service            = each.value
  disable_on_destroy = false
}

module "module function" {
  source = "module/cloudfunctions"

}

resource "random_id" "deploy_suffix" {
  keepers = {
    # Generate a new suffix each time we switch to a new deployment
    deployment_name = "${var.deployment_name}"
  }

  byte_length = 5
}

locals {
  source_files = [
    "${path.root}/src/index.js",
    "${path.root}/package.json",
    "${path.root}/yarn.lock"
  ]
  project = var.project_id
}

data "template_file" "funtion_files" {
  count    = length(local.source_files)
  template = file(element(local.source_files, count.index))
}

resource "google_storage_bucket" "function_artifact_bucket" {
  name                        = "tmfss-fullscan-artifact"
  location                    = var.region
  uniform_bucket_level_access = true
}

data "archive_file" "function_artifact" {
  type        = "zip"
  output_path = "${path.root}/artifact.zip"
  source {
    content  = data.template_file.funtion_files[0].rendered
    filename = basename(data.template_file.funtion_files[0])
  }

  source {
    content  = data.template_file.funtion_files[1].rendered
    filename = basename(data.template_file.funtion_files[1])
  }
  source {
    content  = data.template_file.funtion_files[2].rendered
    filename = basename(data.template_file.funtion_files[2])
  }
}

resource "google_storage_bucket" "bucket" {
  name                        = "${local.project}-gcf-source" # Every bucket name must be globally unique
  location                    = var.region
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "object" {
  name   = "artifact.zip"
  bucket = google_storage_bucket.bucket.name
  source = "${path.root}/artifact.zip"
}

resource "google_service_account" "scan_trigger_sa" {
  account_id   = "tmfss-st-sa"
  display_name = "tmfss-st-sa"
}

resource "google_cloudfunctions2_function" "function" {
  name     = "tmfss-fullscan-plugin-scan-trigger"
  location = var.region

  build_config {
    runtime     = "nodejs20"
    entry_point = "handler"
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.object.name
      }
    }
  }

  service_config {
    service_account_email = google_service_account.scan_trigger_sa
    environment_variables = {
      "SCANNER_PUBSUB_TOPIC" : var.scanner_pubsub_topic
      "SCANNER_PROJECT_ID": var.project_id
      "DEPLOYMENT_NAME": var.deployment_name
    }
  }
}

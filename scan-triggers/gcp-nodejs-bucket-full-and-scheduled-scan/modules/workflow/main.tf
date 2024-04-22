resource "google_cloud_scheduler_job" "workflow" {
  project          = var.project_id
  name             = "TM FSS Full Scan plugin workflow scheduler"
  description      = "Cloud Scheduler for fullscan plugin workflow Jpb"
  schedule         = var.schedular_settings.cron
  time_zone        = var.schedular_settings.time_zone
  attempt_deadline = var.workflow_trigger.cloud_scheduler.deadline
  region           = var.region

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/${google_workflows_workflow.fullscan_workflow.id}/executions"
    body = base64encode(
      jsonencode({
        "argument" : "",
        "callLogLevel" : "CALL_LOG_LEVEL_UNSPECIFIED"
        }
    ))

    oauth_token {
      service_account_email = var.workflow_trigger.cloud_scheduler.service_account_email
      scope                 = "https://www.googleapis.com/auth/cloud-platform"
    }
  }
}

resource "google_service_account" "workflows_sa" {
  account_id   = "tmfss-fullscan-worflow"
  display_name = "Trend Micro FSS Fullscan Plugin Workflows Service Account"
}

resource "google_project_iam_custom_role" "custom_workflow_role" {
  role_id = "tmfssfullscanworkflow"
  title = "TM C1 File storage security fullscan workflow custom role"
  description = "Custom role for FSS fullscan workflow."
  permissions = [
    "storage.objects.list",
    "storage.objects.get",
  ]
}

resource "google_workflows_workflow" "fullscan_workflow" {
  name            = "tmfss-fullscan-workflow"
  description     = "trendmicro fss fullscan plugin workflow."
  service_account = google_service_account.workflows_sa.id
  source_contents = <<-EOF
  - init:
      assgin:
        - project_id: $${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
        - bucket_name: ""
  - listObejcts:
      call: googleapis.storage.v1.objects.list
      args:
          bucket: ""
  EOF

  depends_on = [google_project_service.enable_apis]
}

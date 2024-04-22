variable "project_id" {
  type        = string
  description = "ID of the GCP project which the plugin will be deployed."
  sensitive   = true
}

variable "region" {
  type        = string
  description = "GCP region to deploy the plugin."
}

variable "schedular_settings" {
  type = object({
    cron     = string
    timezone = string
  })
  description = "Settings for the cloud scheduler trigger for workflow. Default to run on every monday at 12:00 AM UTC."
  default = {
    cron     = "0 0 * * 1",
    timezone = "Etc/UTC"
  }
}

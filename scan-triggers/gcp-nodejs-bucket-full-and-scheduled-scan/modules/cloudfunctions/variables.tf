variable "project_id" {
  type        = string
  description = "ID of the GCP project which the plugin will be deployed."
  sensitive   = true
}

variable "region" {
  type        = string
  description = "GCP region to deploy the plugin."
}

variable "scanner_pubsub_topic" {
  type        = string
  description = "Pub/Sub topic to trigger scanner."
}

variable "scanner_pubsub_topic_project" {
  type = string
  description = "Scanner Pub/Sub topic gcp project."
}

variable "deployment_name" {
  type        = string
  description = "The name of the deployment. This is used to generate unique suffix for some resource."
}

variable "report_object_key" {
  type = bool
  default = false
  description = "If true, the report object key will be used instead of sha256."
}

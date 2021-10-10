terraform {
  required_version = ">= 1.0.0"
}

resource "google_service_account" "monitor" {
  account_id   = "is-my-site-up-monitor"
  display_name = "Service account which runs the is-my-site-up monitor"
}

resource "google_service_account_iam_member" "monitor_deployment" {
  for_each           = toset(var.deploying_accounts)
  service_account_id = google_service_account.monitor.name
  role               = "roles/iam.serviceAccountUser"
  member             = each.key
}

resource "random_string" "suffix" {
  length  = 3
  special = false
  number  = false
  upper   = false
}

data "google_client_config" "current_provider" {}

resource "google_storage_bucket" "monitor" {
  name     = "is-my-site-up-monitor-bucket-${random_string.suffix.result}"
  location = data.google_client_config.current_provider.region

  uniform_bucket_level_access = true
}

// Give the monitor service account access to the whole bucket, not just
// the config object, as there is an issue in terraform: if you recreate
// an object then the associated object ACL is not recreated unless the terraform
// is run twice. https://github.com/hashicorp/terraform-provider-google/issues/7671
// is the google provider issue raised on this.
resource "google_storage_bucket_iam_member" "monitor_bucket_access" {
  bucket = google_storage_bucket.monitor.name
  role   = "roles/storage.legacyObjectReader"
  member = "serviceAccount:${google_service_account.monitor.email}"
}

data "archive_file" "monitor_code" {
  type        = "zip"
  source_dir  = "${path.module}/monitor_code"
  output_path = "${path.module}/monitor.zip"
}

resource "google_storage_bucket_object" "monitor_cloud_function_zip" {
  name   = "is-my-site-up-cloud-function-zip"
  bucket = google_storage_bucket.monitor.name
  source = data.archive_file.monitor_code.output_path
}

resource "google_cloudfunctions_function" "is_my_site_up_monitor" {
  name        = "is-my-site-up-monitor"
  description = "This is a cloud function for pinging one or more websites and sending an email if they have a non-200 return code."
  runtime     = "python38"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.monitor.name
  source_archive_object = google_storage_bucket_object.monitor_cloud_function_zip.name
  trigger_http          = true
  entry_point           = "http_entrypoint"
  service_account_email = google_service_account.monitor.email

  environment_variables = {
    GMAIL_ACCOUNT = var.gmail_account
    URLS          = var.urls_to_check
    MONITOR_EMAIL = var.email_to_alert
  }
}

resource "google_cloudfunctions_function_iam_member" "monitor_invoker_perms" {
  project        = google_cloudfunctions_function.is_my_site_up_monitor.project
  region         = google_cloudfunctions_function.is_my_site_up_monitor.region
  cloud_function = google_cloudfunctions_function.is_my_site_up_monitor.name

  role   = "roles/cloudfunctions.invoker"
  member = "serviceAccount:${google_service_account.monitor.email}"
}

resource "google_project_iam_member" "monitor_cloud_run_perms" {
  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.monitor.email}"
}

resource "google_project_iam_member" "monitor_secret_perms" {
  role   = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.monitor.email}"
}

resource "google_cloud_scheduler_job" "monitor_scheduled_job" {
  name             = "is-my-site-up-monitor"
  description      = "Job to trigger the is-my-site-up monitor cloud function"
  schedule         = var.monitor_schedule
  time_zone        = var.monitor_schedule_time_zone
  attempt_deadline = "320s"

  http_target {
    http_method = "GET"
    uri         = google_cloudfunctions_function.is_my_site_up_monitor.https_trigger_url

    oidc_token {
      service_account_email = google_service_account.monitor.email
    }
  }
}

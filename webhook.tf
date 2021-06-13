
resource "google_cloudfunctions_function" "webhook" {
  name                  = "terraform-cloud-notifications"
  description           = "Stores terraform Cloud notifications"
  runtime               = "python39"
  service_account_email = google_service_account.webhook.email


  trigger_http          = true
  timeout               = 300
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.webhook.name
  source_archive_object = google_storage_bucket_object.webhook.name


  entry_point = "store_notifications"
}

resource "google_service_account" "webhook_invoker" {
  account_id = "tfc-notifications-invoker"
}

resource "google_cloudfunctions_function_iam_binding" "webhook_invoker" {
  project        = google_cloudfunctions_function.webhook.project
  region         = google_cloudfunctions_function.webhook.region
  cloud_function = google_cloudfunctions_function.webhook.name
  role           = "roles/cloudfunctions.invoker"
  members = [
    "allUsers",
    format("serviceAccount:%s", google_service_account.webhook_invoker.email)
  ]
}

resource "google_service_account" "webhook" {
  display_name = "Terraform Cloud Notifications"
  account_id   = "terraform-cloud-webhook"
}

resource "google_storage_bucket" "webhook" {
  name     = format("src-terraform-cloud-webhook-%s", data.google_project.default.project_id)
  location = "EU"
}

resource "google_storage_bucket_object" "webhook" {
  name   = "terraform-cloud-notifications-${data.archive_file.webhook.output_md5}.zip"
  bucket = google_storage_bucket.webhook.name
  source = data.archive_file.webhook.output_path
}

data "archive_file" "webhook" {
  type        = "zip"
  source_dir  = "${path.module}/src/"
  output_path = "${path.module}/build/webhook.zip"
}

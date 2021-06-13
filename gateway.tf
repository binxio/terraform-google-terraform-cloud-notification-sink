resource "google_api_gateway_api" "webhook" {
  api_id   = "tfc-notifications"
  display_name = "Terraform Cloud Notifications Webhook API"
  provider = google-beta
}

resource "google_api_gateway_api_config" "webhook" {
  provider      = google-beta
  api           = google_api_gateway_api.webhook.api_id
  api_config_id = "tfc-notifications"


  openapi_documents {
    document {
      path = "openapi.yaml"
      contents = base64encode(
        templatefile(format("%s/src/openapi.yaml", path.module), {
          API_ID      = google_api_gateway_api.webhook.api_id
          BACKEND_URL = google_cloudfunctions_function.webhook.https_trigger_url
      }))
    }
  }

  gateway_config {
    backend_config {
      google_service_account = google_service_account.webhook_invoker.email
    }
  }
  lifecycle {
    create_before_destroy = false
  }
}

resource "google_api_gateway_gateway" "webhook" {
  provider   = google-beta
  api_config = google_api_gateway_api_config.webhook.id
  gateway_id = "tfc-notifications"
}

resource "google_project_service" "webhook" {
  provider           = google-beta
  service            = google_api_gateway_api.webhook.managed_service
  disable_on_destroy = true
}

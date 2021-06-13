
resource "google_bigquery_dataset" "default" {
  dataset_id = "terraform_cloud_notifications"
  location   = "EU"
}


resource "google_bigquery_dataset_iam_member" "bigquery-data-editor-webhook" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = format("serviceAccount:%s", google_service_account.webhook.email)
}

resource "google_bigquery_table" "events" {
  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "events"
  schema     = file(format("%s/data/schema.json", path.module))

  time_partitioning {
    type = "DAY"
    field = "run_created_at"
  }

  clustering = ["run_id", "workspace_name", "organization_name"]
}

resource "google_bigquery_table" "runs" {

  dataset_id = google_bigquery_dataset.default.dataset_id
  table_id   = "runs"

  view {
    use_legacy_sql = false
    query          = <<END
SELECT
  workspace_id,
  run_id,
  pending AS started,
  TIMESTAMP_DIFF(planning, pending, second) plan_wait,
  TIMESTAMP_DIFF(planned, planning, second) planning,
  TIMESTAMP_DIFF(applying, planned, second) apply_wait,
  TIMESTAMP_DIFF(applied, applying, second) applying,
FROM (
  SELECT
    workspace_id,
    run_id,
    run_updated_at,
    run_status
  FROM
    `${google_bigquery_dataset.default.project}.${google_bigquery_dataset.default.dataset_id}.${google_bigquery_table.events.table_id}`,
    UNNEST(notifications) AS n )
PIVOT
(
  MAX(run_updated_at)
  FOR run_status IN ('pending', 'planning', 'planned', 'applying', 'applied')
)
END
  }
}


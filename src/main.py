import logging
import ntpath

from google.cloud import bigquery
from jsonschema import validate
from os import path
import yaml


def read_schema_from_openapi_spec():
    global schema
    filename = path.join(ntpath.dirname(__file__), "openapi.yaml")
    with open(filename, "r") as f:
        spec = yaml.safe_load(f)
        return spec["definitions"]["Notification"]


schema = read_schema_from_openapi_spec()
client = bigquery.Client()


def store(notification: dict):
    table = client.get_table("terraform_cloud_notifications.events")
    result = client.insert_rows_json(
        table=table, json_rows=[notification], ignore_unknown_values=True
    )
    if result:
        logging.error("failed to notification: %s", "\n".join(result))


def is_hook_verification(notification: dict):
    n = notification.get("notifications")
    return n and n[0].get("trigger") == "verification"


def store_notifications(request):
    notification = request.get_json()
    validate(instance=notification, schema=schema)
    if not is_hook_verification(notification):
        store(notification)
    return {"run_id": notification.get("run_id")}

resource "random_password" "t98s-gcf-starter" {
  length  = 8
  special = false
  upper   = false
}

resource "google_storage_bucket" "t98s-gcf-src" {
  provider                    = google-beta
  name                        = "t98s-gcf-src-${random_password.t98s-gcf-starter.result}"
  location                    = local.region
  uniform_bucket_level_access = true
  project                     = local.project
}

resource "google_storage_bucket_object" "gcf-minecraft-starter_zip" {
  name   = basename(var.gcf_minecraft_starter_zip_filepath)
  bucket = google_storage_bucket.t98s-gcf-src.name
  source = var.gcf_minecraft_starter_zip_filepath
}

resource "google_pubsub_topic" "gcf-minecraft-starter" {
  name = "gcf-minecraft-starter"
}

resource "google_cloudfunctions_function" "minecraft-starter-http" {
  name = "minecraft-starter-http"

  source_archive_bucket = google_storage_bucket.t98s-gcf-src.name
  source_archive_object = google_storage_bucket_object.gcf-minecraft-starter_zip.name

  runtime             = "nodejs16"
  available_memory_mb = 256 # 128 だと落ちることがある
  trigger_http        = true
  timeout             = 30
  ingress_settings    = "ALLOW_ALL"
  entry_point         = "interaction"
  environment_variables = {
    DISCORD_APIKEY           = var.discord_apikey
    DISCORD_PUBLIC_KEY       = var.discord_public_key
    DISCORD_APPLICATION_ID   = var.discord_application_id
    GCE_PROJECT_ID           = local.project # 実行環境から取れるかもしれない
    GCE_INSTANCE_RESOURCE_ID = google_compute_instance.minecraft.name
    GCE_INSTANCE_ZONE        = google_compute_instance.minecraft.zone
    GCF_INVOKER_TOPIC        = google_pubsub_topic.gcf-minecraft-starter.name
  }

  service_account_email = google_service_account.minecraft-starter-http.email
}

resource "google_cloudfunctions_function" "minecraft-starter-pubsub" {
  name = "minecraft-starter-pubsub"

  source_archive_bucket = google_storage_bucket.t98s-gcf-src.name
  source_archive_object = google_storage_bucket_object.gcf-minecraft-starter_zip.name

  runtime             = "nodejs16"
  available_memory_mb = 256 # 128 だと落ちることがある
  timeout             = 300
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.gcf-minecraft-starter.id
  }
  ingress_settings = "ALLOW_ALL"
  entry_point      = "startInstance"
  environment_variables = {
    DISCORD_APIKEY           = var.discord_apikey
    DISCORD_PUBLIC_KEY       = var.discord_public_key
    DISCORD_APPLICATION_ID   = var.discord_application_id
    GCE_PROJECT_ID           = local.project # 実行環境から取れるかもしれない
    GCE_INSTANCE_RESOURCE_ID = google_compute_instance.minecraft.name
    GCE_INSTANCE_ZONE        = google_compute_instance.minecraft.zone
    GCF_INVOKER_TOPIC        = google_pubsub_topic.gcf-minecraft-starter.name
  }

  service_account_email = google_service_account.minecraft-starter-pubsub.email
}

resource "google_service_account" "minecraft-starter-http" {
  account_id = "minecraft-starter-http"
}

resource "google_service_account" "minecraft-starter-pubsub" {
  account_id = "minecraft-starter-pubsub"
}

resource "google_pubsub_topic_iam_member" "minecraft-starter-http_pubsub_publisher" {
  project = local.project
  topic   = google_pubsub_topic.gcf-minecraft-starter.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.minecraft-starter-http.email}"
}

resource "google_compute_instance_iam_member" "minecraft-starter-pubsub_instanceStarter" {
  project       = local.project
  zone          = local.zone
  instance_name = google_compute_instance.minecraft.instance_id # インスタンス再生成事に無効化されてしまうのでこのようにインスタンスに依存させる必要がある
  role          = google_project_iam_custom_role.instanceStarter.id
  member        = "serviceAccount:${google_service_account.minecraft-starter-pubsub.email}"
}

resource "google_cloudfunctions_function_iam_member" "minecraft-starter-http_invoker" {
  project        = google_cloudfunctions_function.minecraft-starter-http.project
  region         = google_cloudfunctions_function.minecraft-starter-http.region
  cloud_function = google_cloudfunctions_function.minecraft-starter-http.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}

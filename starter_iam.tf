# #1 が解決されるまでの仮の措置として、インスタンスを開始できる人を指定できるようにする

locals {
  minecraft_starter_gqp = "t98s-micraft-admins@googlegroups.com"
}

resource "google_project_iam_custom_role" "instanceStarter" {
  title       = "instanceStarter"
  role_id     = "instanceStarter"
  permissions = ["compute.instances.start", "compute.instances.stop", "compute.instances.get"]
}

resource "google_project_iam_custom_role" "instanceLister" {
  title       = "instanceLister"
  role_id     = "instanceLister"
  permissions = ["compute.instances.list"]
}

resource "google_compute_instance_iam_member" "instanceStarter" {
  project = local.project
  zone = local.zone
  instance_name = google_compute_instance.minecraft.name
  role = google_project_iam_custom_role.instanceStarter.id
  member = "group:${local.minecraft_starter_gqp}"
}

resource "google_project_iam_member" "instanceLister" {
  project = local.project
  role    = google_project_iam_custom_role.instanceLister.id
  member  = "group:${local.minecraft_starter_gqp}"
}

resource "google_project_iam_member" "projectBrowsers" {
  project = local.project
  role    = "roles/viewer"
  member  = "group:${local.minecraft_starter_gqp}"
}

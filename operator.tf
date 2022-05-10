resource "google_compute_firewall" "iap" {
  name    = "iap-firewall"
  network = google_compute_network.minecraft.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  /* > all IP addresses that IAP uses for TCP forwarding
     > https://cloud.google.com/iap/docs/using-tcp-forwarding */
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["minecraft"]
}

resource "google_project_iam_member" "starter_instanceStandardUser" {
  project  = local.project
  for_each = toset(["roles/compute.osLogin", "roles/iap.tunnelResourceAccessor"])
  role     = each.key
  member   = "group:${local.minecraft_starter_gqp}"
}

resource "google_service_account_iam_member" "starter_instanceStandardUser" {
  service_account_id = google_service_account.minecraft.name
  role               = "roles/iam.serviceAccountUser"
  member             = "group:${local.minecraft_starter_gqp}"
}

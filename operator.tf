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

resource "google_compute_instance_iam_member" "starter_instanceStandardUser" {
  project = local.project
  zone    = local.zone
  /* 具体的なリソースに紐付けられている IAM policy であることに注意
     google_compute_instance.name を渡すと、同名のまま作り直されたときに効果を失うことになる */
  instance_name = google_compute_instance.minecraft.instance_id
  for_each      = ["roles/compute.osLogin", "roles/iap.tunnelResourceAccessor"]
  role          = each.key
  member        = "group:${local.minecraft_starter_gqp}"
}

resource "google_project_service" "cloudbuild" {
  service                    = "cloudbuild.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "pubsub" {
  service                    = "pubsub.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "cloudfunctions" {
  service                    = "cloudfunctions.googleapis.com"
  disable_dependent_services = true
}

resource "google_project_service" "compute" {
  service                    = "compute.googleapis.com"
  disable_dependent_services = true
}


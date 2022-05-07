terraform {
  backend "gcs" {
    bucket = "t98s-minecraft-server-terraform"
  }
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.20.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "4.20.0"
    }
  }
}

locals {
  project = "t98s-minecraft-server"
  region  = "asia-northeast1"
  zone    = "asia-northeast1-a"
}

provider "google" {
  project = local.project
  region  = local.region
}

provider "google-beta" {
  project = local.project
  region  = local.region
}

resource "google_compute_instance" "minecraft" {
  name                    = "minecraft-instance"
  machine_type            = "n1-standard-2"
  zone                    = local.zone
  tags                    = ["minecraft"]
  metadata_startup_script = "docker run -d --rm --name mcserver -p 42865:25565 -e EULA=TRUE -e VERSION=1.18.2 -e MEMORY=4G -e OPS=rinsuki,takanakahiko -v /var/minecraft:/data itzg/minecraft-server:latest;"
  metadata = {
    enable-oslogin  = "TRUE"
    shutdown-script = "docker exec mcserver rcon-cli stop"
  }
  boot_disk {
    auto_delete = false
    source      = google_compute_disk.minecraft.self_link
  }
  network_interface {
    network = google_compute_network.minecraft.name
    access_config {
      nat_ip = google_compute_address.minecraft.address
    }
  }
  service_account {
    email  = google_service_account.minecraft.email
    scopes = ["userinfo-email"]
  }
  scheduling {
    preemptible       = true
    automatic_restart = false
  }
}

resource "google_service_account" "minecraft" {
  account_id   = "minecraft-sa"
  display_name = "minecraft-sa"
}

resource "google_compute_disk" "minecraft" {
  name  = "minecraft-disk"
  type  = "pd-standard"
  zone  = local.zone
  image = "cos-cloud/cos-stable"
}

resource "google_compute_address" "minecraft" {
  name   = "minecraft-ip"
  region = local.region
}

resource "google_compute_network" "minecraft" {
  name = "minecraft-network"
}

resource "google_compute_firewall" "minecraft" {
  name    = "minecraft-firewall"
  network = google_compute_network.minecraft.name
  allow {
    protocol = "tcp"
    ports    = ["42865"] # <- otaku
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["minecraft"]
}

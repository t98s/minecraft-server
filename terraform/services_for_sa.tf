# Owner が操作するときにはなにもせずに使えるのに、Service Account から操作するときには service が有効でなければならないシリーズ
# これらは有効である前提なので、別ファイルに分けている

resource "google_project_service" "iam" {
  service = "iam.googleapis.com"
}

resource "google_project_service" "iamcredentials" {
  service = "iamcredentials.googleapis.com"
}

resource "google_project_service" "cloudresourcemanager" {
  service = "cloudresourcemanager.googleapis.com"
}

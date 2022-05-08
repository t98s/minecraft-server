variable "discord_apikey" {
  type      = string
  sensitive = true
}

variable "discord_public_key" {
  type      = string
  sensitive = true
}

variable "discord_application_id" {
  type      = string
  sensitive = true
}

variable "github_repository" {
  type    = string
  default = "t98s/minecraft-server"
}

variable "gcf_minecraft_starter_zip_filepath" {
  type = string
}

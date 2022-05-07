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

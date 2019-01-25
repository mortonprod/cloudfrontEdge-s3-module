variable "name" {
  default = "wgl-site"
}
variable "aws_region" {
}

variable "domain_names" {
  description = "Only supports sub domain changes"
  type = "list"
}

variable "asset_folder" {
  description = "Only supports sub domain changes"
}

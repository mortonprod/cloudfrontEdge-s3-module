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

variable "content_security_policy" {
  description = "This is the content security policy to set for the origin."
  default = "default-src 'self'; connect-src 'self' ses.alexandermorton.co.uk; script-src 'self' cdnjs.cloudflare.com code.getmdl.io code.jquery.com; style-src 'self' code.getmdl.io fonts.googleapis.com; font-src 'self' code.getmdl.io fonts.googleapis.com fonts.gstatic.com"
}
variable "name" {
  default = "wgl-site"
}
variable "aws_region" {
  default = "us-east-1"
}

variable "domain_names" {
  description = "Only supports sub domain changes"
  default = ["www.alex-test-site.co.uk", "test.alex-test-site.co.uk"]
}

terraform {
  backend "s3" {
    # CAN SET THIS HERE ON IN MAKE FILE.
    # bucket = "wgl-site-terraform-state"
    # key    = "wgl-site"
    # region = "eu-west-2"
    # dynamodb_table = "wgl-site-terraform-state"
  }
}

provider "aws" {
  region      = "${var.aws_region}"
}

module "cloudfrontEdge-s3-module" {
  source = ".."
  name = "${var.name}"
  aws_region = "${var.aws_region}"
  domain_names = "${var.domain_names}"
  asset_folder = "${var.asset_folder}"
}
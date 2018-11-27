terraform {
  backend "s3" {
    bucket = "wgl-site-terraform-state"
    key    = "wgl-site"
    region = "eu-west-2"
    dynamodb_table = "wgl-site-terraform-state"
  }
}

provider "aws" {
  region      = "${var.aws_region}"
}
provider "aws" {
  region  = "us-east-1"
  alias   = "us-east-1"
}

data "archive_file" "file" {
  type        = "zip"
  source_dir = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda_function_originRequest" {
  function_name    = "lambda_function_originRequest"
  filename         = "lambda.zip"
  handler          = "handler.originRequest"
  source_code_hash = "${data.archive_file.file.output_base64sha256}"
  role             = "${aws_iam_role.iam_role.arn}"
  runtime          = "nodejs8.10"
  memory_size      = 128
  timeout          = 1
}

resource "aws_lambda_function" "lambda_function_originResponse" {
  function_name    = "lambda_function_originResponse"
  filename         = "lambda.zip"
  handler          = "handler.originResponse"
  source_code_hash = "${data.archive_file.file.output_base64sha256}"
  role             = "${aws_iam_role.iam_role.arn}"
  runtime          = "nodejs8.10"
  memory_size      = 128
  timeout          = 1
}

resource "aws_iam_role" "iam_role" {
  name               = "goLambda"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": {
    "Action": "sts:AssumeRole",
    "Principal": {
      "Service": "lambda.amazonaws.com"
    },
    "Effect": "Allow"
  }
}
POLICY
}
resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "${var.name}"
  # policy        = "${data.template_file.bucket_policy.rendered}"
  force_destroy = true

  website {
    index_document = "index.html"
    error_document = "404.html"
  }

}

data "aws_acm_certificate" "acm_certificate" {
  provider = "aws.us-east-1"

  domain   = "${var.domain_name}"
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {

  enabled      = true
  price_class  = "PriceClass_100"
  http_version = "http1.1"

  origin {
    origin_id = "origin-bucket-${aws_s3_bucket.s3_bucket.id}"

    # This is the endpoint of the s3 bucket
    domain_name = "${aws_s3_bucket.s3_bucket.website_endpoint}"

    custom_origin_config {
      origin_protocol_policy = "https-only"

      http_port            = "80"
      https_port           = "443"
      origin_ssl_protocols = ["TLSv1"]
    }
  }

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods = ["HEAD", "GET"]

    cached_methods = ["HEAD", "GET"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.lambda_function_originRequest.arn}"
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.lambda_function_originResponse.arn}"
    }

    min_ttl = "0"

    default_ttl      = "300"                           
    max_ttl          = "1200"                         
    target_origin_id = "origin-bucket-${var.name}"

    viewer_protocol_policy = "redirect-to-https"
    compress               = true
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = "${data.aws_acm_certificate.acm_certificate.arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1"
  }
  aliases = ["${var.domain_name}"]

}

# data "aws_route53_zone" "selected" {
#   count = "${length(var.domain_names)}"

#   # This will get the domain from the full domain name (with sub domain) and then retrieve the right zone.
#   name = "${element(split(".", var.domain_name),0) != "" ? replace(var.domain_name,"${element(split(".", var.domain_name),0)}.", "") : replace(var.domain_name, "/(^)[.]/", "")}"
# }

# # // TTL 60 seconds.
# resource "aws_route53_record" "elb_alias" {
#   count   = "${length(var.domain_names)}"
#   zone_id = "${element(data.aws_route53_zone.selected.*.zone_id, count.index)}"
#   name    = "${replace(var.domain_name, "/(^)[.]/", "")}"
#   type    = "A"

#   alias {
#     name = "${element(var.cloudfront_domain_names, count.index)}"

#     zone_id                = "${element(var.cloudfront_hostzone_ids, count.index)}"
#     evaluate_target_health = false
#   }
# }

# resource "aws_lambda_permission" "goLambda" {
#   statement_id  = "AllowAPIGatewayInvoke"
#   action        = "lambda:InvokeFunction"
#   function_name = "${aws_lambda_function.goLambda.arn}"
#   principal     = "apigateway.amazonaws.com"
# }

# resource "aws_api_gateway_resource" "goLambda" {
#   rest_api_id = "${aws_api_gateway_rest_api.goLambda.id}"
#   parent_id   = "${aws_api_gateway_rest_api.goLambda.root_resource_id}"
#   path_part   = "goLambda"
# }

# resource "aws_api_gateway_rest_api" "goLambda" {
#   name = "goLambda"
# }

# #           GET
# # Internet -----> API Gateway
# resource "aws_api_gateway_method" "goLambda" {
#   rest_api_id   = "${aws_api_gateway_rest_api.goLambda.id}"
#   resource_id   = "${aws_api_gateway_resource.goLambda.id}"
#   http_method   = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "goLambda" {
#   rest_api_id             = "${aws_api_gateway_rest_api.goLambda.id}"
#   resource_id             = "${aws_api_gateway_resource.goLambda.id}"
#   http_method             = "${aws_api_gateway_method.goLambda.http_method}"
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${aws_lambda_function.goLambda.arn}/invocations"
# }

# # This resource defines the URL of the API Gateway.
# resource "aws_api_gateway_deployment" "goLambda_v1" {
#   depends_on = [
#     "aws_api_gateway_integration.goLambda"
#   ]
#   rest_api_id = "${aws_api_gateway_rest_api.goLambda.id}"
#   stage_name  = "v1"
# }

# # Set the generated URL as an output. Run `terraform output url` to get this.
# output "url" {
#   value = "${aws_api_gateway_deployment.goLambda_v1.invoke_url}${aws_api_gateway_resource.goLambda.path}"
# }

# data "aws_acm_certificate" "goLambda" {
#   domain   = "${var.domain}"
#   statuses = ["ISSUED"]
# }

# resource "aws_api_gateway_domain_name" "goLambda" {
#   domain_name = "${var.subDomainLambda}.${var.domain}"
#   certificate_arn = "${data.aws_acm_certificate.goLambda.arn}"
# }

# # resource "aws_route53_zone" "main" {
# #   name = "${var.domain}"
# # }

# data "aws_route53_zone" "main" {
#   name         = "${var.domain}"
#   # private_zone = true
# }


# resource "aws_route53_record" "goLambda" {
#   zone_id = "${data.aws_route53_zone.main.id}" 

#   name = "${aws_api_gateway_domain_name.goLambda.domain_name}"
#   type = "A"

#   alias {
#     name                   = "${aws_api_gateway_domain_name.goLambda.cloudfront_domain_name}"
#     zone_id                = "${aws_api_gateway_domain_name.goLambda.cloudfront_zone_id}"
#     evaluate_target_health = true
#   }
# }

# resource "aws_api_gateway_base_path_mapping" "goLambda" {
#   api_id      = "${aws_api_gateway_rest_api.goLambda.id}"
#   stage_name  = "${aws_api_gateway_deployment.goLambda_v1.stage_name}"
#   domain_name = "${aws_api_gateway_domain_name.goLambda.domain_name}"
# }

# resource "aws_route53_record" "assets" {
#   zone_id = "${data.aws_route53_zone.main.id}"
#   name    = "cats"
#   type    = "CNAME"
#   ttl     = "5"

#   # weighted_routing_policy {
#   #   weight = 10
#   # }

#   # set_identifier = "dev"
#   records        = ["c.storage.googleapis.com"]
# }
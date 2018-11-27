# Need to set this with make file but does not let you set.
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

# data "aws_acm_certificate" "cert" {
#   provider = "aws.us-east-1"
#   count    = "${length(var.domain_names)}"

#   # This will get the domain from the full domain name (with sub domain) and then retrieve the right zone.
#   domain   = "${element(split(".", element(var.domain_names, count.index)),0) != "" ? replace(element(var.domain_names, count.index),"${element(split(".", element(var.domain_names, count.index)),0)}.", "") : replace(element(var.domain_names, count.index), "/(^)[.]/", "")}"
#   statuses = ["ISSUED"]
# }

# resource "aws_cloudfront_distribution" "website_cdn" {
#   count = "${length(var.domain_names)}"

#   # Should we allow end users to access content 
#   enabled      = true
#   price_class  = "${var.price_class}"
#   http_version = "http1.1"

#   "origin" {
#     # This is just a unique name for the origin
#     origin_id = "origin-bucket-${var.bucket_id}"

#     # This is the endpoint of the s3 bucket
#     domain_name = "${var.website_endpoint}"

#     custom_origin_config {
#       origin_protocol_policy = "https-only"

#       http_port            = "80"
#       https_port           = "443"
#       origin_ssl_protocols = ["TLSv1"]
#     }

#     # s3_origin_config {}

#     # 
#     # custom_header {
#     #   name  = "x-frame-options"
#     #   value = "SAME-ORIGIN"
#     # }
#     # custom_header {
#     #   name  = "strict-transport-security"
#     #   value = "max-age=15552000; includeSubDomains"
#     # }
#     # custom_header {
#     #   name  = "x-content-type-options"
#     #   value = "nosniff"
#     # }
#     # custom_header {
#     #   name  = "x-xss-protection"
#     #   value = "1; mode=block"
#     # }
#     # custom_header {
#     #   name  = "content-security-policy"
#     #   value = "default-src 'self'; script-src 'self' 'unsafe-eval'; style-src 'self' 'unsafe-inline' fonts.googleapis.com; font-src 'self' fonts.googleapis.com fonts.gstatic.com"
#     # }
#     # custom_header {
#     #   name  = "referrer-policy"
#     #   value = "same-origin"
#     # }
#   }

#   default_root_object = "index.html"

#   # custom_error_response {
#   #   error_code            = "404"
#   #   error_caching_min_ttl = "360"
#   #   response_code         = "200"
#   #   response_page_path    = "${var.not_found_response_path}"
#   # }

#   "default_cache_behavior" {
#     # Should only ever allow get requests to get frontends 
#     # Must include HEAD.
#     allowed_methods = ["HEAD", "GET"]

#     # Cache the frontends
#     cached_methods = ["HEAD", "GET"]

#     "forwarded_values" {
#       // We should never need to forward queries to get frontend
#       query_string = false

#       # Don't need to forwards cookies.
#       cookies {
#         forward = "none"
#       }
#     }

#     lambda_function_association {
#       event_type = "origin-response"
#       lambda_arn = "${lookup(var.cloudfront_event_lambda,"${terraform.workspace}.origin-response")}"
#     }

#     lambda_function_association {
#       event_type = "origin-request"
#       lambda_arn = "${lookup(var.cloudfront_event_lambda,"${terraform.workspace}.origin-request")}"
#     }

#     # trusted_signers = ["${var.trusted_signers}"]
#     # This is the time cloudfront waits before it queries the origin again.
#     min_ttl = "0"

#     default_ttl      = "300"                            //3600
#     max_ttl          = "1200"                           //86400
#     target_origin_id = "origin-bucket-${var.bucket_id}"

#     // This redirects any HTTP request to HTTPS. Security first!
#     viewer_protocol_policy = "redirect-to-https"
#     compress               = true
#   }
#   "restrictions" {
#     "geo_restriction" {
#       restriction_type = "none"
#     }
#   }
#   "viewer_certificate" {
#     acm_certificate_arn      = "${element(data.aws_acm_certificate.cert.*.arn, count.index)}"
#     ssl_support_method       = "sni-only"
#     minimum_protocol_version = "TLSv1"
#   }
#   aliases = ["${element(var.domain_names, count.index)}"]

#   #   tags = "${merge("${var.tags}",map("Name", "${var.project}-${var.environment}-${var.domain}", "Environment", "${var.environment}", "Project", "${var.project}"))}"
# }

# data "aws_route53_zone" "selected" {
#   count = "${length(var.domain_names)}"

#   # This will get the domain from the full domain name (with sub domain) and then retrieve the right zone.
#   name = "${element(split(".", element(var.domain_names, count.index)),0) != "" ? replace(element(var.domain_names, count.index),"${element(split(".", element(var.domain_names, count.index)),0)}.", "") : replace(element(var.domain_names, count.index), "/(^)[.]/", "")}"
# }

# # // TTL 60 seconds.
# resource "aws_route53_record" "elb_alias" {
#   count   = "${length(var.domain_names)}"
#   zone_id = "${element(data.aws_route53_zone.selected.*.zone_id, count.index)}"
#   name    = "${replace(element(var.domain_names, count.index), "/(^)[.]/", "")}"
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
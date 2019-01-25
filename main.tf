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
# provider "aws" {
#   region  = "us-east-1"
#   alias   = "us-east-1"
# }

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
  publish = true
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
  publish = true
}

# resource "aws_lambda_alias" "lambda_alias" {
#   name             = "testalias"
#   description      = "a sample description"
#   function_name    = "${aws_lambda_function.lambda_function_originResponse.arn}"
#   function_version = "1"
# }


resource "aws_lambda_permission" "lambda_permission_request" {
  statement_id   = "AllowExecutionFromCloudFront"
  action         = "lambda:GetFunction"
  function_name  = "${aws_lambda_function.lambda_function_originRequest.function_name}"
  principal      = "replicator.lambda.amazonaws.com"
  # qualifier = "1"
}

resource "aws_lambda_permission" "lambda_permission_response" {
  statement_id   = "AllowExecutionFromCloudFront"
  action         = "lambda:GetFunction"
  function_name  = "${aws_lambda_function.lambda_function_originResponse.function_name}"
  principal      = "replicator.lambda.amazonaws.com"
  # qualifier = "1"
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "edgelambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "iam_role" {
  name = "iam_for_lambda"

  assume_role_policy = "${data.aws_iam_policy_document.instance_role.json}"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role = "${aws_iam_role.iam_role.name}"
  policy_arn = "arn:aws:iam::442357565108:policy/service-role/AWSLambdaEdgeExecutionRole-e2b0323f-afc0-4d83-b256-b43117520803"
}


resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "s3-bucket-${var.name}"
    # acl    = "public-read"
  # policy        = "${data.template_file.bucket_policy.rendered}"
  # force_destroy = true

  # website {
  #   index_document = "index.html"
  #   error_document = "404.html"
  # }

}

resource "aws_cloudfront_origin_access_identity" "cloudfront_origin_access_identity" {
  comment = "${var.name}"
}

resource "null_resource" "resource_remove_and_upload_to_s3" {
  triggers {
    always = "${uuid()}"
  }
  provisioner "local-exec" {
    command = "aws s3 sync ${var.asset_folder} s3://${aws_s3_bucket.s3_bucket.id}"
  }
}

# resource "aws_s3_bucket_object" "s3_bucket_object_html" {
#   bucket = "${aws_s3_bucket.s3_bucket.id}"
#   content_type = "text/html"
#   key    = "index.html"
#   # source = "./website/dist/index.html"
#   source = "${var.}"
# }

# resource "aws_s3_bucket_object" "s3_bucket_object_js" {
#   bucket = "${aws_s3_bucket.s3_bucket.id}"
#   content_type = "text/js"
#   key    = "app.bundle.js"
#   source = "./website/dist/app.bundle.js"
# }

resource "aws_s3_bucket_policy" "s3_bucket_policy" {
  bucket = "${aws_s3_bucket.s3_bucket.id}"

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Id": "Policy1380877762691",
    "Statement": [
        {
            "Sid": "Stmt1380877761162",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.cloudfront_origin_access_identity.id}"
            },
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::s3-bucket-${var.name}/*"
        }
    ]
}
POLICY
}


data "aws_acm_certificate" "acm_certificate" {
  # count = "${length(var.domain_names)}"
  # provider = "aws.us-east-1"

  domain   = "${element(split(".", var.domain_names[0]),0) != "" ? replace(var.domain_names[0],"${element(split(".", var.domain_names[0]),0)}.", "") : replace(var.domain_names[0], "/(^)[.]/", "")}"
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {

  enabled      = true
  price_class  = "PriceClass_100"
  http_version = "http1.1"

  origin {
    origin_id = "${aws_s3_bucket.s3_bucket.id}"

    # This is the endpoint of the s3 bucket
    domain_name = "${aws_s3_bucket.s3_bucket.bucket_regional_domain_name}"

    # custom_origin_config {
    #   origin_protocol_policy = "https-only"

    #   http_port            = "80"
    #   https_port           = "443"
    #   origin_ssl_protocols = ["TLSv1"]
    # }
    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/${aws_cloudfront_origin_access_identity.cloudfront_origin_access_identity.id}"
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
      event_type = "origin-request"
      lambda_arn = "${aws_lambda_function.lambda_function_originRequest.qualified_arn}"
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = "${aws_lambda_function.lambda_function_originResponse.qualified_arn}"
    }

    min_ttl = "0"

    default_ttl      = "300"                           
    max_ttl          = "1200"                         
    target_origin_id = "${aws_s3_bucket.s3_bucket.id}"

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
  aliases = "${var.domain_names}"

}

data "aws_route53_zone" "route53_zome" {
  # count = "${length(var.domain_names)}"
  name = "${element(split(".", var.domain_names[0]),0) != "" ? replace(var.domain_names[0],"${element(split(".", var.domain_names[0]),0)}.", "") : replace(var.domain_names[0], "/(^)[.]/", "")}"
}

# // TTL 60 seconds.
resource "aws_route53_record" "route53_record" {
  count = "${length(var.domain_names)}"
  zone_id = "${data.aws_route53_zone.route53_zome.zone_id}"
  name    = "${var.domain_names[count.index]}"
  type    = "A"

  alias {
    name = "${aws_cloudfront_distribution.cloudfront_distribution.domain_name}"

    zone_id                = "${aws_cloudfront_distribution.cloudfront_distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

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
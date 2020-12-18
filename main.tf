data "archive_file" "file" {
  type        = "zip"
  source_dir = "${path.module}/lambda"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "lambda_function_originRequest" {
  function_name    = "${var.name}-lambda_function_originRequest"
  filename         = "${path.module}/lambda.zip"
  handler          = "handler.originRequest"
  source_code_hash = "${data.archive_file.file.output_base64sha256}"
  role             = "${aws_iam_role.iam_role.arn}"
  runtime          = "nodejs12.x"
  memory_size      = 128
  timeout          = 1
  publish = true
}


resource "aws_lambda_function" "lambda_function_originResponse" {
  function_name    = "${var.name}-lambda_function_originResponse"
  filename         = "${path.module}/lambda.zip"
  handler          = "handler.originResponse"
  source_code_hash = "${data.archive_file.file.output_base64sha256}"
  role             = "${aws_iam_role.iam_role.arn}"
  runtime          = "nodejs12.x"
  memory_size      = 128
  timeout          = 1
  publish = true
}


resource "aws_lambda_permission" "lambda_permission_request" {
  statement_id   = "AllowExecutionFromCloudFront"
  action         = "lambda:GetFunction"
  function_name  = "${aws_lambda_function.lambda_function_originRequest.function_name}"
  principal      = "replicator.lambda.amazonaws.com"
}

resource "aws_lambda_permission" "lambda_permission_response" {
  statement_id   = "AllowExecutionFromCloudFront"
  action         = "lambda:GetFunction"
  function_name  = "${aws_lambda_function.lambda_function_originResponse.function_name}"
  principal      = "replicator.lambda.amazonaws.com"
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
  name = "${var.name}-iam_for_lambda"

  assume_role_policy = "${data.aws_iam_policy_document.instance_role.json}"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment" {
  role = "${aws_iam_role.iam_role.name}"
  policy_arn = "arn:aws:iam::442357565108:policy/service-role/AWSLambdaEdgeExecutionRole-e2b0323f-afc0-4d83-b256-b43117520803"
}

data "archive_file" "init" {
  type        = "zip"
  source_dir = "${var.asset_folder}"
  output_path = "assets.zip"
}


resource "aws_s3_bucket" "s3_bucket" {
  bucket        = "s3-bucket-${var.name}"
  force_destroy = true
}

resource "aws_cloudfront_origin_access_identity" "cloudfront_origin_access_identity" {
  comment = "${var.name}"
}

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

  domain   = "${element(split(".", var.domain_names[0]),0) != "" ? replace(var.domain_names[0],"${element(split(".", var.domain_names[0]),0)}.", "") : replace(var.domain_names[0], "/(^)[.]/", "")}"
  statuses = ["ISSUED"]
}

resource "aws_cloudfront_distribution" "cloudfront_distribution" {

  enabled      = true
  price_class  = "PriceClass_100"
  http_version = "http1.1"

  origin {
    origin_id = "${aws_s3_bucket.s3_bucket.id}"
    domain_name = "${aws_s3_bucket.s3_bucket.bucket_regional_domain_name}"
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

    min_ttl = "0" // Min time should be zero so we get index file each time.
    default_ttl      = "86400" // Keep in cache for a 1 day by default.
    max_ttl          = "2592000" // Keep in cache for a 30 days at the most.
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
  name = "${element(split(".", var.domain_names[0]),0) != "" ? replace(var.domain_names[0],"${element(split(".", var.domain_names[0]),0)}.", "") : replace(var.domain_names[0], "/(^)[.]/", "")}"
}

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
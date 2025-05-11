provider "aws" {
  region = "us-east-1"
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-cloudfront-oac"
  description                       = "Access to S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

locals {
  s3_origin_id = "myS3Origin"
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  # 658327ea‑f89d‑4fab‑a63d‑7e88639e58f6  – official ID for CachingOptimized
  id = "658327ea-f89d-4fab-a63d-7e88639e58f6" # :contentReference[oaicite:0]{index=0}
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled     = true
  price_class = "PriceClass_100"

  # Default object - English home page
  default_root_object = "index.html"

  # Alternate domain
  aliases = [var.website_URL]

  # S3 origin
  origin {
    domain_name              = aws_s3_bucket.website-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  # Default cache behavior
  default_cache_behavior {
    target_origin_id = local.s3_origin_id

    # Methods
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # **Modern** caching config – no Accept‑Language forwarded to S3
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    # Redirect HTTP -> HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # forwarded_values {
    #   query_string = false
    #   headers      = ["Accept-Language"]

    #   cookies {
    #     forward = "none"
    #   }
    # }

    lambda_function_association {
      # event_type = "origin-request"
      event_type   = "viewer-request" # must run *before* cache lookup :contentReference[oaicite:1]{index=1}
      lambda_arn   = aws_lambda_function.terraform_lambda_func.qualified_arn
      include_body = false
    }

    # min_ttl     = 0
    # default_ttl = 1
    # max_ttl     = 1
  }

  # No geo restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

# S3 bucket policy restricted to *this* distribution (least privilege)
data "aws_iam_policy_document" "cloudfront_oac_access_website" {
  statement {
    sid = "AllowCloudFrontReadViaOAC"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website-bucket.arn}/*"]

    # Grant access only when the request comes from this distribution
    condition { # :contentReference[oaicite:2]{index=2}
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website-bucket-policy" {
  bucket = aws_s3_bucket.website-bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access_website.json
}

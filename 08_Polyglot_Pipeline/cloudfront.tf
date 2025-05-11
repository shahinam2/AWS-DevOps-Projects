# AWS Provider configuration
provider "aws" {
  region = "us-east-1"
}

# CloudFront Origin Access Control for S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-cloudfront-oac"
  description                       = "Access to S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Local variable for S3 origin ID
locals {
  s3_origin_id = "myS3Origin"
}

# Reference to AWS managed cache policy for optimized caching
# 658327ea‑f89d‑4fab‑a63d‑7e88639e58f6  – official ID for CachingOptimized
# See: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/using-managed-cache-policies.html
data "aws_cloudfront_cache_policy" "caching_optimized" {
  id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

# CloudFront Distribution for S3 static website
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled     = true
  price_class = "PriceClass_100"

  # Default object - English home page
  default_root_object = "index.html"

  # Alternate domain name(s) for the distribution
  aliases = [var.website_URL]

  # S3 origin configuration
  origin {
    domain_name              = aws_s3_bucket.website-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = local.s3_origin_id
  }

  # Default cache behavior configuration
  default_cache_behavior {
    target_origin_id = local.s3_origin_id

    # Allowed and cached HTTP methods
    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    # Use optimized cache policy (no Accept‑Language forwarded)
    cache_policy_id = data.aws_cloudfront_cache_policy.caching_optimized.id

    # Redirect HTTP to HTTPS
    viewer_protocol_policy = "redirect-to-https"

    # Lambda@Edge association for viewer requests
    lambda_function_association {
      event_type   = "viewer-request" # must run *before* cache lookup
      lambda_arn   = aws_lambda_function.terraform_lambda_func.qualified_arn
      include_body = false
    }
  }

  # No geo restrictions for content delivery
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL/TLS certificate configuration
  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

# S3 bucket policy to allow CloudFront OAC read access (least privilege)
data "aws_iam_policy_document" "cloudfront_oac_access_website" {
  statement {
    sid = "AllowCloudFrontReadViaOAC"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website-bucket.arn}/*"]

    # Restrict access to requests from this CloudFront distribution only
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

# Attach the above policy to the S3 bucket
resource "aws_s3_bucket_policy" "website-bucket-policy" {
  bucket = aws_s3_bucket.website-bucket.id
  policy = data.aws_iam_policy_document.cloudfront_oac_access_website.json
}

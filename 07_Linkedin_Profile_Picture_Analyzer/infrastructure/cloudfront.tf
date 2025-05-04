##########################################################################################
################################# Cloudfront #############################################
##########################################################################################
# Cloudfront distribution for the frontend S3 bucket 
resource "aws_cloudfront_distribution" "frontend_distribution" {
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id # Attach the OAC to the CloudFront distribution
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "https-only"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # if this is not set, then cloudfront won't be listed in the route53 as an alias
  aliases = [
    "${var.SUBDOMAIN}.${var.HOSTED_ZONE_NAME}" # linkedin-pp-analyzer.aws-lab.click
  ]

  viewer_certificate {
    acm_certificate_arn      = var.ACM_CERTIFICATE_ARN
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  price_class = "PriceClass_100"
  depends_on  = [aws_s3_bucket.frontend_bucket]

  # WAF association
  web_acl_id = aws_wafv2_web_acl.cloudfront_waf.arn
}

# Cloudfront origin access control (OAC) for the frontend S3 bucket
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name        = "frontend-oac"
  description = "OAC for CloudFront to access the frontend S3 bucket"

  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}



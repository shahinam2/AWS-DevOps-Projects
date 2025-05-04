##########################################################################################
################################# CloudFront (SPA‑ready) #################################
##########################################################################################
# A small CloudFront Function makes every request that *doesn’t look like* a file (no dot
# in the last path segment) resolve to /index.html so Clerk’s “?token=…” or any client‑
# side router path renders the SPA instead of returning 403/404 from S3.
resource "aws_cloudfront_function" "spa_rewrite" {
  name    = "spa-add-index-html"
  runtime = "cloudfront-js-2.0"
  publish = true

  code = <<EOF
function handler(event) {
  var req = event.request;
  // If the URI is "/" OR ends with "/" OR has no period (no file-extension)
  if (req.uri === "/" || req.uri.endsWith("/") || !req.uri.split("/").pop().includes(".")) {
    req.uri = "/index.html";
  }
  // Strip the query-string so S3 gets a clean key.  Remove these two lines if you *do*
  // want to keep the query parameters for Lambda@Edge or logging.
  req.querystring = {};
  return req;
}
  EOF
}

##########################################################################################
################################# CloudFront Distribution ################################
##########################################################################################
resource "aws_cloudfront_distribution" "frontend_distribution" {
  enabled = true

  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.cloudfront_waf.arn # WAF association

  # ----------------------------------------------------------------------------------------------------------------
  # Origin: S3 bucket behind OAC (private)
  # ----------------------------------------------------------------------------------------------------------------
  origin {
    domain_name              = aws_s3_bucket.frontend_bucket.bucket_regional_domain_name
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.frontend_oac.id
  }

  # ----------------------------------------------------------------------------------------------------------------
  # Default behaviour – attaches the SPA rewrite function and disables caching so the
  # same index.html is served for every virtual path.
  # ----------------------------------------------------------------------------------------------------------------
  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD", "OPTIONS"]

    # Don’t include query‑strings or cookies in the cache key so Clerk tokens don’t
    # explode the cache.
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    # Attach the CloudFront Function
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_rewrite.arn
    }
  }

  # ----------------------------------------------------------------------------------------------------------------
  # Aliases & TLS – must match the SANs on your us‑east‑1 ACM certificate.
  # ----------------------------------------------------------------------------------------------------------------
  aliases = [
    "${var.SUBDOMAIN}.${var.HOSTED_ZONE_NAME}" # e.g. linkedin-pp-analyzer.aws-lab.click
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

  # Re‑use the bucket creation as an implicit dependency so the distribution doesn’t
  # deploy before the origin is ready.
  depends_on = [aws_s3_bucket.frontend_bucket]
}

##########################################################################################
######################## CloudFront Origin Access Control (OAC) ###########################
##########################################################################################
resource "aws_cloudfront_origin_access_control" "frontend_oac" {
  name                              = "frontend-oac"
  description                       = "OAC for CloudFront to access the frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


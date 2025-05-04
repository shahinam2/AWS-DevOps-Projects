##########################################################################################
################################# WAF for Cloudfront #####################################
##########################################################################################
# Create a WAF WebACL with AWS Managed Rules
resource "aws_wafv2_web_acl" "cloudfront_waf" {
  name        = "cloudfront-waf"
  provider    = aws.us_east_1
  description = "WAF for CloudFront distribution with AWS Managed Rules"
  scope       = "CLOUDFRONT" # Must be CLOUDFRONT for CloudFront distributions
  default_action {
    allow {}
  }
  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "cloudfront-waf"
    sampled_requests_enabled   = false
  }

  # Add AWS Managed Rules for protection against common web application vulnerabilities
  # which includes:
  # - SQL Injection (SQLi)
  # - Cross-Site Scripting (XSS)
  # - Cross-Site Request Forgery (CSRF)
  # - Distributed Denial of Service (DDoS)
  # - Broken Authentication
  # - Sensitive Data Exposure
  # - Security Misconfiguration
  # - Insecure Deserialization
  # - Broken Access Control
  # - Bot Attacks
  # - Zero-Day Vulnerabilities
  # - Man-in-the-Middle (MITM) Attacks
  # - API Abuse
  # - File Upload Vulnerabilities
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = false
    }
  }
}

# Associate the WAF WebACL with the CloudFront distribution
# resource "aws_wafv2_web_acl_association" "cloudfront_waf_association" {
#   provider     = aws.us_east_1
#   resource_arn = aws_cloudfront_distribution.frontend_distribution.arn
#   web_acl_arn  = aws_wafv2_web_acl.cloudfront_waf.arn
# }

##########################################################################################
################################### WAF for API Gateway ##################################
##########################################################################################

# Unfortunately, AWS WAFv2 does not support API Gateway v2 (HTTP API) directly.
# I should either add a cloudfront distribution in front of the API Gateway or rewrite the API Gateway to use v1 (REST API).
# For now, I'm adding this comment here to remind myself to do this later.

# Create an A record in Route 53 to point to the CloudFront distribution
resource "aws_route53_record" "website_alias" {
  zone_id = var.route53_zone_id
  name    = var.website_URL
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

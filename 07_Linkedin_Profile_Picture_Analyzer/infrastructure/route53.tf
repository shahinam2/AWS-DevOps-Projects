##########################################################################################
########################################## Route53 #######################################
##########################################################################################
# Ensure the hosted zone exists for your domain
data "aws_route53_zone" "main_zone" {
  name = var.HOSTED_ZONE_NAME
}

# Add a subdomain record for linkedin-pp-checker
resource "aws_route53_record" "subdomain" {
  zone_id = data.aws_route53_zone.main_zone.zone_id
  name    = var.SUBDOMAIN
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.frontend_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.frontend_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}

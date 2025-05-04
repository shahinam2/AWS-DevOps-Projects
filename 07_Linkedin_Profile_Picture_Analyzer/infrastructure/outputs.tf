################################################################################
################################# Output #######################################
################################################################################
# Output frontend bucket name
output "frontend_bucket" {
  description = "The name of the S3 bucket for the frontend."
  value       = aws_s3_bucket.frontend_bucket.bucket
}

# Output upload bucket name
output "upload_bucket" {
  value = aws_s3_bucket.upload_bucket.bucket
}

# Remove the unsupported data source and directly use the aws_apigatewayv2_stage resource
output "api_gateway_base_url" {
  value       = aws_apigatewayv2_stage.dev_stage.invoke_url
  description = "The base URL for the API Gateway."
}

# Output the CloudFront distribution domain name 
output "cloudfront_distribution_domain" {
  description = "The domain name of the CloudFront distribution."
  value       = aws_cloudfront_distribution.frontend_distribution.domain_name
}

# Output CloudFront distribution ID
output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution."
  value       = aws_cloudfront_distribution.frontend_distribution.id
}

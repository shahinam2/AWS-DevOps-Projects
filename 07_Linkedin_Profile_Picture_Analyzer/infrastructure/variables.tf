variable "JWKS_URL" {
  description = "The URL for the JWKS"
  type        = string
  default     = "https://improved-buffalo-76.clerk.accounts.dev"
}

variable "AWS_REGION" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "eu-central-1"
}

variable "ACM_CERTIFICATE_ARN" {
  description = "The ARN of the ACM certificate for CloudFront"
  type        = string
  default     = "arn:aws:acm:us-east-1:593793041840:certificate/4252603e-9701-4fa1-812c-779c7ae4295b"
}

variable "HOSTED_ZONE_NAME" {
  description = "The custom domain name for the frontend S3 bucket"
  type        = string
  default     = "aws-lab.click"
}

variable "SUBDOMAIN" {
  description = "The subdomain for the frontend S3 bucket"
  type        = string
  default     = "linkedin-pp-analyzer"
}

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

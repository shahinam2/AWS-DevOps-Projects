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

variable "Terraform_State_Bucket" {
  description = "The name of the S3 bucket for Terraform state"
  type        = string
  default     = "terraform-state-bucket-593793041840"
}

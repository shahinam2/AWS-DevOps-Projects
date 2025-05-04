# Provider configuration for AWS
provider "aws" {
  region = var.AWS_REGION
}

# This configuration is used to store the Terraform remote state file in an S3 bucket
# Make sure bucket versioning is enabled
terraform {
  backend "s3" {
    bucket       = var.Terraform_State_Bucket
    key          = "terraform.tfstate"
    region       = var.AWS_REGION
    use_lockfile = false # Enable this when you are in a team
  }
}

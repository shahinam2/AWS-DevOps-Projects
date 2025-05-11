variable "website_bucket_name" {
  description = "The name of the S3 bucket for all website content (multi-language)"
  type        = string
  default     = "conference-website-bucket"
}

# This is the bucket name for the CodePipeline to store the artifacts.
variable "codepipeline_bucket_name" {
  description = "The name of the S3 bucket for CodePipeline artifacts"
  type        = string
  default     = "polyglotpipeline-artifacts-bucket"
}

# This is the main repo where the original HTML, CSS and the translator file are stored.
variable "github_repository_url" {
  description = "GitHub repository in the format <owner>/<repo>"
  type        = string
  default     = "shahinam2/polyglot-pipeline" # This should not be a full URL.
}

variable "website_URL" {
  description = "The domain name for the website (e.g., aws-lab.click)."
  type        = string
  default     = "aws-lab.click"
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate for the CloudFront distribution"
  type        = string
  default     = "arn:aws:acm:us-east-1:593793041840:certificate/4252603e-9701-4fa1-812c-779c7ae4295b"
}

variable "route53_zone_id" {
  description = "The Route 53 Hosted Zone ID for the domain."
  type        = string
  default     = "Z102713426CPG7AHNQQQF"
}

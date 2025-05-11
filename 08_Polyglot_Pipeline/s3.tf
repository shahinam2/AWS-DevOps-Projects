# conference site S3 bucket for all languages
resource "aws_s3_bucket" "website-bucket" {
  bucket = var.website_bucket_name
}

# S3 bucket to store pipeline artifacts
resource "aws_s3_bucket" "codepipeline_bucket" {
  bucket = var.codepipeline_bucket_name
}

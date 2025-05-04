##########################################################################################
############################# S3 Bucket for uploading Images #############################
##########################################################################################
# Create random ID to use as a suffix for the S3 bucket name
# resource "random_id" "suffix" {
#   byte_length = 10
# }

# Get the AWS account ID to use in the bucket name
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "upload_bucket" {
  bucket        = "profile-store-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

# Update the lifecycle rule to remove files after 1 day
resource "aws_s3_bucket_lifecycle_configuration" "upload_bucket_lifecycle" {
  bucket = aws_s3_bucket.upload_bucket.id

  rule {
    id     = "RemoveOldFiles"
    status = "Enabled"
    filter {
      prefix = "" # Apply to all objects in the bucket
    }
    expiration {
      days = 1
    }
  }
}

# This gives both Lambdas (image_uploader and rekognition) put and get access to the S3 bucket.
data "aws_iam_policy_document" "lambda_s3_access" {
  statement {
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${aws_s3_bucket.upload_bucket.arn}/*"]
    effect    = "Allow"
  }
}

##########################################################################################
################################# Frontend Bucket ########################################
##########################################################################################
# Create frontend S3 bucket with a unique name using random ID
resource "aws_s3_bucket" "frontend_bucket" {
  bucket        = "profile-store-frontend-${random_id.suffix.hex}"
  force_destroy = true
}

# Enable static website hosting on the S3 bucket
resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend_bucket.id

  index_document {
    suffix = "index.html"
  }
}

# S3 policy to allow public access to the S3 bucket
resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_bucket.arn}/*"
      }
    ]
  })
  depends_on = [aws_s3_bucket_public_access_block.frontend_access_block]
}

# Add a resource to disable the "Block Public Access" setting for the frontend bucket
resource "aws_s3_bucket_public_access_block" "frontend_access_block" {
  bucket = aws_s3_bucket.frontend_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

###############################################################################
###### Upload EVERYTHING (including the freshly‑generated config.json) ########
###############################################################################
# MIME‑type helper map
# locals {
#   mime_types = {
#     html = "text/html"
#     css  = "text/css"
#     js   = "application/javascript"
#     jpg  = "image/jpeg"
#     jpeg = "image/jpeg"
#     png  = "image/png"
#     gif  = "image/gif"
#   }
# }

# resource "aws_s3_object" "frontend_files" {
#   for_each = fileset("../frontend", "**/*")

#   bucket = aws_s3_bucket.frontend_bucket.id
#   key    = each.value
#   source = "../frontend/${each.value}"

#   # pick the mime‑type from the map, default to binary
#   content_type = lookup(
#     local.mime_types,
#     regex("[^.]*$", each.value), # grab the file extension
#     "application/octet-stream"
#   )
# }

################################################################################
###################### upload the generated config #############################
################################################################################
# resource "aws_s3_object" "config_json" {
#   bucket       = aws_s3_bucket.frontend_bucket.id
#   key          = "config.json"
#   source       = local_file.frontend_config.filename
#   content_type = "application/json"

#   depends_on = [local_file.frontend_config] # make sure it’s written first
# }

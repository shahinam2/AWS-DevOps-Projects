####################################################################################
############################# Rekognition Function #################################
####################################################################################
# Archive file for Rekognition Lambda function
data "archive_file" "zip_rekognition_func" {
  type        = "zip"
  source_file = "../backend/rekognition.py"
  output_path = "../backend/rekognition.zip"
}

# Rekognition Lambda function configuration
resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "../backend/rekognition.zip"
  function_name = "Analyze_Function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "rekognition.lambda_handler"
  runtime       = "python3.13"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  environment {
    variables = {
      REKOGNITION_QUEUE_URL = aws_sqs_queue.rekognition_queue.url
      DYNAMODB_TABLE_NAME   = aws_dynamodb_table.profile_results.name
    }
  }
}

# SQS trigger for Rekognition Lambda function
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.rekognition_queue.arn
  function_name    = aws_lambda_function.terraform_lambda_func.arn
  batch_size       = 10
  enabled          = true
}

####################################################################################
############################# Uploader function ####################################
####################################################################################
# Archive file for Image Uploader Lambda function
data "archive_file" "image_uploader_zip" {
  type        = "zip"
  source_file = "../backend/image_uploader.py"
  output_path = "../backend/image_uploader.zip"
}

# Image Uploader Lambda function configuration
resource "aws_lambda_function" "image_uploader_func" {
  filename      = data.archive_file.image_uploader_zip.output_path
  function_name = "ImageConverter_Function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "image_uploader.lambda_handler"
  runtime       = "python3.13"
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_s3_access]
  memory_size   = 128
  timeout       = 30
  environment {
    variables = {
      IMAGE_BUCKET_NAME     = aws_s3_bucket.upload_bucket.bucket
      REKOGNITION_QUEUE_URL = aws_sqs_queue.rekognition_queue.url
    }
  }
}

####################################################################################
############################# Get Result function ##################################
####################################################################################
# Archive file for Get Result Lambda function
data "archive_file" "get_result_zip" {
  type        = "zip"
  source_file = "../backend/get_result.py"
  output_path = "../backend/get_result.zip"
}

# Get Result Lambda function configuration
resource "aws_lambda_function" "get_result_func" {
  filename      = data.archive_file.get_result_zip.output_path
  function_name = "GetResult_Function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "get_result.lambda_handler"
  runtime       = "python3.13"
  depends_on    = [aws_iam_role_policy_attachment.attach_lambda_dynamodb_access]
  memory_size   = 128
  timeout       = 30
  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.profile_results.name
    }
  }
}

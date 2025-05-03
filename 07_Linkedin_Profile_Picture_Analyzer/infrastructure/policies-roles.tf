#################################################################################
############################# IAM Role and Policies #############################
#################################################################################
# IAM Role for Lambda function with assume role policy
resource "aws_iam_role" "lambda_role" {
  name = "Detection_Lambda_Function_Role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# IAM Policy for Lambda function to access CloudWatch logs
resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  path        = "/"
  description = "AWS IAM Policy for lambda role"
  policy = jsonencode({    # json encode is used to convert the policy document to JSON format
    Version = "2012-10-17" # as suggested by terraform documentation: 
    Statement = [          # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      },
    ]
  })
}

# IAM Policy Document to allow invoking other Lambda functions
data "aws_iam_policy_document" "invoke_other_lambda" {
  statement {
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.terraform_lambda_func.arn
    ]
  }
}

# Attach IAM Policy to Lambda Role for invoking Lambda
resource "aws_iam_role_policy_attachment" "attach_invoke_lambda" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.allow_invoke_rekognition_lambda.arn
}

#################################################################################
############################# CloudWatch Logs Policy ############################
#################################################################################
# Attach IAM Policy for CloudWatch logs to Lambda Role
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

################################################################################
############################# Rekognition Access Policy ########################
################################################################################
# Data source for Rekognition ReadOnlyAccess policy
data "aws_iam_policy" "rekognition_policy" {
  arn = "arn:aws:iam::aws:policy/AmazonRekognitionReadOnlyAccess"
}

# Attach Rekognition policy to Lambda Role
resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = data.aws_iam_policy.rekognition_policy.arn
}

# IAM Policy to allow invoking Rekognition Lambda function
resource "aws_iam_policy" "allow_invoke_rekognition_lambda" {
  name   = "AllowInvokeRekognitionLambda"
  policy = data.aws_iam_policy_document.invoke_other_lambda.json
}

################################################################################
############################# SQS Access Policy ################################
################################################################################
# IAM Policy Document for SQS access
data "aws_iam_policy_document" "sqs_access_policy" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.rekognition_queue.arn]
    effect    = "Allow"
  }
}

# IAM Policy for SQS access
resource "aws_iam_policy" "sqs_access_policy" {
  name   = "AllowLambdaSQSSendMessage"
  policy = data.aws_iam_policy_document.sqs_access_policy.json
}

# Attach SQS access policy to Lambda Role
resource "aws_iam_role_policy_attachment" "attach_lambda_sqs_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sqs_access_policy.arn
}

# IAM Policy Document for SQS receive permissions
data "aws_iam_policy_document" "sqs_receive_policy" {
  statement {
    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"]
    resources = [aws_sqs_queue.rekognition_queue.arn]
    effect    = "Allow"
  }
}

# IAM Policy for SQS receive permissions
resource "aws_iam_policy" "sqs_receive_policy" {
  name   = "AllowLambdaSQSReceiveMessage"
  policy = data.aws_iam_policy_document.sqs_receive_policy.json
}


# Attach SQS receive policy to Lambda Role
resource "aws_iam_role_policy_attachment" "attach_lambda_sqs_receive" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.sqs_receive_policy.arn
}

####################################################################################
############################# S3 Access Policy #####################################
####################################################################################
# IAM Policy Document for S3 access
data "aws_iam_policy_document" "s3_access_policy" {
  statement {
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = ["${aws_s3_bucket.upload_bucket.arn}/*"]
    effect    = "Allow"
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access_policy" {
  name   = "AllowLambdaFullS3Access"
  policy = data.aws_iam_policy_document.s3_access_policy.json
}

# Attach S3 access policy to Lambda Role
resource "aws_iam_role_policy_attachment" "attach_lambda_s3_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

################################################################################
############################ DynamoDB Access Policy ############################
################################################################################
# IAM Policy Document for DynamoDB access
data "aws_iam_policy_document" "dynamodb_access_policy" {
  statement {
    actions   = ["dynamodb:PutItem", "dynamodb:GetItem"]
    resources = [aws_dynamodb_table.profile_results.arn]
    effect    = "Allow"
  }
}

# IAM Policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_access_policy" {
  name   = "AllowLambdaDynamoDBAccess"
  policy = data.aws_iam_policy_document.dynamodb_access_policy.json
}

# Attach DynamoDB access policy to Lambda Role
resource "aws_iam_role_policy_attachment" "attach_lambda_dynamodb_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}
####################################################################################

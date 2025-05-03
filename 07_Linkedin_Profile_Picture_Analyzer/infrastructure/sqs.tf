##########################################################################################
###################################### SQS Queue #########################################
##########################################################################################
resource "aws_sqs_queue" "rekognition_queue" {
  name                       = "rekognition-queue"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600
  delay_seconds              = 0
  receive_wait_time_seconds  = 0
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "dlq" {
  name                      = "rekognition-dlq"
  message_retention_seconds = 1209600
}

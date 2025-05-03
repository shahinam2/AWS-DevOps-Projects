####################################################################################
######################## DynamoDB Table for Profile Results ########################
####################################################################################
resource "aws_dynamodb_table" "profile_results" {
  name         = "profile_results"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "image_id"

  attribute {
    name = "image_id"
    type = "S"
  }
}

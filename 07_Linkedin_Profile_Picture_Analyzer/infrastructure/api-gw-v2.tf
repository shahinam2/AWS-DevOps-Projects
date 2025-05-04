###################################################################################
############################# API Gateway V2 Configuration ########################
###################################################################################
// Define the API Gateway with HTTP protocol and CORS configuration
resource "aws_apigatewayv2_api" "http_api" {
  name          = "LinkedIn-Photo-Analyzer-API"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins  = ["*"]
    allow_methods  = ["OPTIONS", "POST", "GET"]
    allow_headers  = ["Content-Type", "Authorization"]
    expose_headers = ["Access-Control-Allow-Origin"]
    max_age        = 3600
  }
}
// Set up the deployment stage & autodeploy for the API Gateway
resource "aws_apigatewayv2_stage" "dev_stage" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "dev"
  auto_deploy = true
}

##################################################################################
################################# /upload route ##################################
##################################################################################
// Define the route for the API Gateway to handle POST requests to /upload
resource "aws_apigatewayv2_route" "post_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "POST /upload"
  target             = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.clerk_authorizer.id
}

// Configure the integration between API Gateway and the Lambda function
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.image_uploader_func.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

// Grant API Gateway permission to invoke the Lambda function
resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.image_uploader_func.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

###################################################################################
############################# /result Route #######################################
###################################################################################
// Define the route for the API Gateway to handle GET requests to /result
resource "aws_apigatewayv2_route" "get_result_route" {
  api_id             = aws_apigatewayv2_api.http_api.id
  route_key          = "GET /result"
  target             = "integrations/${aws_apigatewayv2_integration.get_result_integration.id}"
  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.clerk_authorizer.id
}

// Configure the integration between API Gateway and the Get Result Lambda function
resource "aws_apigatewayv2_integration" "get_result_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.get_result_func.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

// Grant API Gateway permission to invoke the Get Result Lambda function
resource "aws_lambda_permission" "allow_api_gateway_get_result" {
  statement_id  = "AllowAPIGatewayInvokeGetResult"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_result_func.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

###################################################################################
############################# Authorizer Configuration ############################
###################################################################################
resource "aws_apigatewayv2_authorizer" "clerk_authorizer" {
  api_id           = aws_apigatewayv2_api.http_api.id
  name             = "${aws_apigatewayv2_api.http_api.id}-clerk-jwt" # to avoid name collision
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  jwt_configuration {
    audience = ["linkedin-photo-api"]
    issuer   = var.JWKS_URL
  }
}

###############################################################################
# Create config.json after the stage is ready
###############################################################################
# transferred this to the frontend workflow
# resource "local_file" "frontend_config" {
#   filename = "../frontend/config.json"

# jsonencode guarantees valid JSON
#   content = jsonencode({
#     base_url = aws_apigatewayv2_stage.dev_stage.invoke_url
#   })
# }

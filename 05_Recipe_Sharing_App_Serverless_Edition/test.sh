
LAMBDAS_BUCKET_NAME="recipe-sharing-lambdas-20325412023424"
AWS_REGION="eu-central-1"
echo "🔍 Checking if S3 bucket '$LAMBDAS_BUCKET_NAME' exists in region '$AWS_REGION'..."
if aws s3api head-bucket --bucket "$LAMBDAS_BUCKET_NAME" 2>/dev/null; then
  echo "✅ Bucket '$LAMBDAS_BUCKET_NAME' already exists."
else
  echo "⚠️ Bucket '$LAMBDAS_BUCKET_NAME' does not exist. Creating..."
  aws s3api create-bucket \
    --bucket "$LAMBDAS_BUCKET_NAME" \
    --region "$AWS_REGION" \
    --create-bucket-configuration LocationConstraint="$AWS_REGION"
  echo "🎉 Bucket '$LAMBDAS_BUCKET_NAME' created successfully."
fi
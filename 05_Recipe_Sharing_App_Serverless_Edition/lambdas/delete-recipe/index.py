import json
import boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('recipes')
def lambda_handler(event, context):
    try:
        recipe_id = event['pathParameters']['recipe_id']
        response = table.delete_item(
            Key={
                'id': recipe_id
            }
        )
        return {
            "statusCode": 200,
            "body": json.dumps({"message": "Recipe deleted successfully"})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"message": f"Error deleting recipe: {e}"})
        }
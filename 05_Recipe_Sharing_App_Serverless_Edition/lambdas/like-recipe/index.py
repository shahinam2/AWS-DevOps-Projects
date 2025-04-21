import json
import boto3
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('recipes')
def lambda_handler(event, context):
    
    recipe_id = event['pathParameters']['recipe_id']
    print(recipe_id)
    try:
        response = table.update_item(
            Key={'id': recipe_id},
            UpdateExpression='SET likes = likes + :val',
            ExpressionAttributeValues={':val': 1},
            ReturnValues='UPDATED_NEW'
        )
        return {"message": "Recipe liked successfully"}
    except Exception as e:
        return {"message": f"Error liking recipe: {e}"}
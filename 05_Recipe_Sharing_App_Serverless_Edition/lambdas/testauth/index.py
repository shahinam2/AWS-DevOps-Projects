import json
def lambda_handler(event, context):
    response = {
        "statusCode": 200,
        "body": json.dumps({"message": "You've passed the authentication token"})
    }
    return response
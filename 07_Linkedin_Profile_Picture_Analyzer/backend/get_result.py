import json, os, boto3
from boto3.dynamodb.conditions import Key
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
table    = dynamodb.Table(os.getenv("DYNAMODB_TABLE_NAME", "profile_results"))

def _conv(o):
    # DynamoDB numbers → JS numbers
    if isinstance(o, Decimal):
        return float(o)
    raise TypeError

def lambda_handler(event, _):
    qs = event.get("queryStringParameters") or {}
    image_id = qs.get("image_id")
    if not image_id:
        return {"statusCode": 400,
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": "query param image_id is required"}

    resp = table.get_item(Key={"image_id": image_id})

    if "Item" not in resp:                 # not ready yet
        return {"statusCode": 202,         # 202 Accepted
                "headers": {"Access-Control-Allow-Origin": "*"},
                "body": json.dumps({"ready": False})}

    return {"statusCode": 200,
            "headers": {"Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"ready": True, "data": resp["Item"]},
                               default=_conv)}

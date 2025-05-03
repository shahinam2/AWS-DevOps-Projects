import base64, binascii, json, logging, mimetypes, os, uuid

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

s3   = boto3.client("s3")
sqs  = boto3.client("sqs")

BUCKET_NAME          = os.environ["IMAGE_BUCKET_NAME"]
REKOGNITION_QUEUE_URL = os.environ["REKOGNITION_QUEUE_URL"]

# ───────────────────────── helper ────────────────────────────
def _decode_image_b64(b64_string: str) -> bytes:
    """Return raw bytes from a base-64 string (no data-URL prefix)."""
    try:
        return base64.b64decode(b64_string, validate=True)
    except binascii.Error as e:
        raise ValueError("file_content must be valid base-64") from e

# ───────────────────────── handler ───────────────────────────
def lambda_handler(event, _):
    logger.info("Raw event: %s", json.dumps(event)[:1000])

    # CORS pre-flight
    if (event.get("httpMethod") or
        event.get("requestContext", {}).get("http", {}).get("method")) == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "POST,OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type",
            },
            "body": "",
        }

    # API Gateway can mark the body as base-64
    if event.get("isBase64Encoded"):
        raw_bytes = base64.b64decode(event["body"])
        file_name = event["headers"].get("x-file-name") or f"{uuid.uuid4()}.jpg"
        content_type = event["headers"].get("content-type") or "image/jpeg"
    else:
        body = json.loads(event["body"] or "{}")
        file_name     = body.get("file_name") or f"{uuid.uuid4()}.jpg"
        raw_bytes     = _decode_image_b64(body["file_content"])
        content_type, _ = mimetypes.guess_type(file_name)
        content_type = content_type or "application/octet-stream"

    # ── upload to S3 ─────────────────────────────────────────
    logger.info("Uploading %s (%s bytes) to bucket %s", file_name, len(raw_bytes), BUCKET_NAME)
    s3.put_object(
        Bucket=BUCKET_NAME,
        Key=file_name,
        Body=raw_bytes,
        ContentType=content_type,
    )

    s3_uri = f"s3://{BUCKET_NAME}/{file_name}"

    # ── send SQS message ─────────────────────────────────────
    sqs.send_message(QueueUrl=REKOGNITION_QUEUE_URL,
                     MessageBody=json.dumps({"s3_path": s3_uri}))

    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "POST,OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type",
        },
        "body": json.dumps({"message": "upload ok", "s3_path": s3_uri}),
    }
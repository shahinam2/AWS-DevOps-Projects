# analyze_image.py  ── Lambda handler for SQS → Rekognition → DynamoDB
#
#  • Reads an SQS message that contains {"s3_path": "s3://bucket/key"}.
#  • Runs Rekognition quality + moderation checks.
#  • Stores one row per message in DynamoDB table   profile_results
#      - partition key: record_id   (String – the SQS messageId)
#      - attributes :  s3_path, status, issues (StringSet), scores (Map<Number>)
#
#  Required IAM:
#      rekognition:DetectFaces, rekognition:DetectModerationLabels
#      s3:GetObject   on the bucket
#      dynamodb:PutItem  on the table
#
#  Required environment variables:
#      DYNAMODB_TABLE_NAME   (defaults to "profile_results")
# ---------------------------------------------------------------------------

import json, logging, os
from urllib.parse import urlparse
from decimal import Decimal
from pathlib import PurePosixPath

import boto3
from botocore.exceptions import ClientError

# ─────────────── setup ───────────────
logger = logging.getLogger()
logger.setLevel(logging.INFO)

rekognition = boto3.client("rekognition")
dynamodb    = boto3.resource("dynamodb")
TABLE_NAME  = os.environ.get("DYNAMODB_TABLE_NAME", "profile_results")
table       = dynamodb.Table(TABLE_NAME)

# ─────────────── helpers ─────────────
def split_s3(uri: str):
    p = urlparse(uri)
    if p.scheme != "s3":
        raise ValueError(f"Not s3:// URI: {uri}")
    return p.netloc, p.path.lstrip("/")

def to_decimal(obj):
    if isinstance(obj, float):
        return Decimal(str(obj))
    if isinstance(obj, list):
        return [to_decimal(v) for v in obj]
    if isinstance(obj, dict):
        return {k: to_decimal(v) for k, v in obj.items()}
    return obj

# ─────────────── handler ─────────────
def lambda_handler(event, _):
    logger.info("Event: %s", json.dumps(event)[:1000])
    results = []

    for rec in event.get("Records", []):
        try:
            body        = json.loads(rec["body"])
            s3_path     = body["s3_path"]                     # "s3://bucket/key.jpg"
            bucket, key = split_s3(s3_path)
            image_ref   = {"S3Object": {"Bucket": bucket, "Name": key}}

            # derive the table's primary-key value
            image_id = PurePosixPath(key).name               # "key.jpg"

            # ── Rekognition ------------------------------------------------
            faces = rekognition.detect_faces(Image=image_ref, Attributes=["ALL"])["FaceDetails"]
            if len(faces) != 1:
                issue = "no_face" if len(faces) == 0 else "multiple_faces"
                item = {
                    "image_id" : image_id,
                    "record_id": rec["messageId"],
                    "s3_path"  : s3_path,
                    "status"   : "Bad",
                    "issues"   : [issue],
                    "scores"   : {}, 
                }
                table.put_item(Item=item)
                logger.info("Wrote %s with issue %s", image_id, issue)
                results.append({"id": rec["messageId"], "write": "OK"})
                continue                              # go to next SQS record

                # raise ValueError("Image must contain exactly one face")
            face = faces[0]

            checks = {
                "face_confidence": face["Confidence"] > 95,
                "sharp_image":     face["Quality"]["Sharpness"] > 70,
                "well_lit":        face["Quality"]["Brightness"] > 50,
                "smiling":         face["Smile"]["Value"],
                "eyes_open":       face["EyesOpen"]["Value"],
                "no_sunglasses":   not face.get("Sunglasses", {}).get("Value", False),
                "frontal_face":    max(abs(face["Pose"][a]) for a in ("Yaw","Pitch","Roll")) < 20,
                "emotion_ok":      max(face["Emotions"],
                                       key=lambda e: e["Confidence"])["Type"] in ("HAPPY", "CALM"),
            }

            mods = rekognition.detect_moderation_labels(Image=image_ref,
                                                        MinConfidence=80)["ModerationLabels"]
            mod_names = [m["Name"] for m in mods]

            status = "Good" if all(checks.values()) and not mod_names else "Bad"
            issues = [k for k,v in checks.items() if not v] + [f"moderation:{m}" for m in mod_names]

            item = {
                "image_id":  image_id,                 # ← table’s key
                "record_id": rec["messageId"],         # extra traceability
                "s3_path":   s3_path,
                "status":    status,
                "issues":    issues,
                "scores": {
                    "face_confidence": round(face["Confidence"], 2),
                    "sharpness":       round(face["Quality"]["Sharpness"], 2),
                    "brightness":      round(face["Quality"]["Brightness"], 2),
                    "smile":           round(face["Smile"]["Confidence"], 2),
                    "eyes_open":       round(face["EyesOpen"]["Confidence"], 2)
                }
            }

            table.put_item(Item=to_decimal(item))
            logger.info("Wrote %s to %s", image_id, TABLE_NAME)
            results.append({"id": rec["messageId"], "write": "OK"})

        except ClientError as aws_err:
            logger.error("AWS error for %s: %s", rec.get("messageId"), aws_err)
            results.append({"id": rec.get("messageId"), "write": "ERROR"})
        except Exception as err:
            logger.error("Record %s failed: %s", rec.get("messageId"), err)
            results.append({"id": rec.get("messageId"), "write": "ERROR"})

    return {
        "statusCode": 200,
        "body": json.dumps({"processed": len(results), "results": results})
    }
import boto3
import pymysql
from botocore.exceptions import ClientError

# AWS Secrets Manager details
SECRET_ARN = "arn:aws:secretsmanager:eu-central-1:593793041840:secret:rds!db-b157cc33-1a08-414c-abc4-b228af92a151-bUkpHL"
AWS_REGION = "eu-central-1"

# RDS details
RDS_ENDPOINT = "emaildb2.cdk2s8kc8bdk.eu-central-1.rds.amazonaws.com"
RDS_DB_NAME = "EmailDB2"

def get_secret(secret_arn):
    """Fetch secret from AWS Secrets Manager."""
    try:
        client = boto3.client("secretsmanager", region_name=AWS_REGION)
        response = client.get_secret_value(SecretId=secret_arn)
        secret = response["SecretString"]
        return eval(secret)  # Convert the secret string to a dictionary
    except ClientError as e:
        print(f"Error retrieving secret: {e}")
        return None

# Fetch credentials from Secrets Manager
credentials = get_secret(SECRET_ARN)
if not credentials:
    print("Failed to retrieve credentials from Secrets Manager.")
    exit(1)

# Extract username and password from the secret
username = credentials.get("username")
password = credentials.get("password")

try:
    # Establish the connection
    connection = pymysql.connect(
        host=RDS_ENDPOINT,
        user=username,
        password=password,
        database=RDS_DB_NAME
    )
    print("Connection to AWS RDS MySQL database was successful!")

    # Optionally, test a query
    with connection.cursor() as cursor:
        cursor.execute("SELECT DATABASE();")
        result = cursor.fetchone()
        print("Connected to database:", result[0])

except Exception as e:
    print("Failed to connect to the database.")
    print("Error:", e)

finally:
    if 'connection' in locals() and connection.open:
        connection.close()
        print("Connection closed.")
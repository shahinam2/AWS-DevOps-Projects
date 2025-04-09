import os
import boto3
from botocore.exceptions import ClientError
from flask import Flask, render_template, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text

# Load environment variables
DB_ENDPOINT = os.getenv('DB_ENDPOINT', 'localhost')
DB_NAME = os.getenv('DB_NAME', 'default_db')
AWS_REGION = os.getenv('AWS_REGION', 'us-east-1')
SECRET_ARN = os.getenv('DB_SECRET_ARN', 'default_secret_arn')

# Fetch the secret value from AWS Secrets Manager
def get_secret(secret_arn):
    try:
        client = boto3.client(
            service_name='secretsmanager',
            region_name=AWS_REGION
        )
        response = client.get_secret_value(SecretId=secret_arn)
        return response['SecretString']
    except ClientError as e:
        print(f"Error retrieving secret: {e}")
        return None

# Fetch credentials from Secrets Manager
secret_value = get_secret(SECRET_ARN)
if not secret_value:
    print("Failed to retrieve credentials from Secrets Manager.")
    exit(1)

app = Flask(__name__)
# app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///./email.db'
# app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://<username>:<password>@<endpoint>/<database-name>'
app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql+pymysql://admin:{secret_value}@{DB_ENDPOINT}/{DB_NAME}'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

with app.app_context():
    # Create users table if it does not exist
    users_table = text(""" 
    CREATE TABLE IF NOT EXISTS users(
    username VARCHAR(255) NOT NULL PRIMARY KEY,
    email VARCHAR(255));
    """)
    db.session.execute(users_table)

    # Check if the table is empty and insert initial data if it is
    existing_data = db.session.execute(text("SELECT COUNT(*) FROM users")).scalar()
    print(existing_data)
    if existing_data == 0:
        data = text("""
        INSERT INTO users
        VALUES
            ("dora", "dora@amazon.com"),
            ("cansin", "cansin@google.com"),
            ("sencer", "sencer@bmw.com"),
            ("uras", "uras@mercedes.com"),
            ("ares", "ares@porche.com");
        """)
        db.session.execute(data)
        db.session.commit()

def find_emails(keyword):
    with app.app_context():
        query = text(f"""
        SELECT username, email FROM users WHERE username LIKE '%{keyword}%';
        """)
        result = db.session.execute(query)
        user_emails = []

        # Safely unpack rows
        for row in result:
            if len(row) == 2:  # Ensure the row has exactly two elements
                user_emails.append((row[0], row[1]))

        # Handle case where no results are found
        if not user_emails:
            user_emails = "User not found"

        return user_emails

def insert_email(name, email):
    with app.app_context():
        query = text("""
        SELECT * FROM users WHERE username = :name
        """)
        result = db.session.execute(query, {"name": name}).fetchone()
        response = ''
        if len(name) == 0 or len(email) == 0:
            response = 'Username or email cannot be empty!'
        elif not result:
            insert = text("""
            INSERT INTO users (username, email)
            VALUES (:name, :email)
            """)
            db.session.execute(insert, {"name": name, "email": email})
            db.session.commit()
            response = f"User {name} with email {email} has been added successfully."
        else:
            response = f"User {name} already exists."
        return response

@app.route('/', methods=['GET', 'POST'])
def index():
    feedback = None
    if request.method == 'POST':
        # Check which form was submitted
        if 'user_keyword' in request.form:  # Find email form
            user_app_name = request.form['user_keyword']
            user_emails = find_emails(user_app_name)
            return render_template('index.html', name_emails=user_emails, feedback=None)
        elif 'username' in request.form and 'useremail' in request.form:  # Add email form
            user_app_name = request.form['username']
            user_app_email = request.form['useremail']
            feedback = insert_email(user_app_name, user_app_email)
    return render_template('index.html', feedback=feedback, name_emails=None)

# - Add a statement to run the Flask application which can be reached from any host on port 80.
if __name__=='__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)

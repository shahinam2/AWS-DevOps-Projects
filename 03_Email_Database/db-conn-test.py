import pymysql

# Replace with your RDS MySQL credentials
host = "your-rds-endpoint.amazonaws.com"  # Replace with your actual RDS endpoint
user = "admin"  # Replace with your actual username
password = "your_password"  # Replace with your actual password
database = "emaildb"  # Replace with your actual database name

try:
    # Establish the connection
    connection = pymysql.connect(
        host=host,
        user=user,
        password=password,
        database=database
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
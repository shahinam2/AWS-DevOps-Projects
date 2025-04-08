from flask import Flask, render_template, request
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import text
app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///./email.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
db = SQLAlchemy(app)

with app.app_context():
    drop_table = text('DROP TABLE IF EXISTS users;')
    users_table = text(""" 
    CREATE TABLE users(
    username VARCHAR NOT NULL PRIMARY KEY,
    email VARCHAR);
    """)
    data = text("""
    INSERT INTO users
    VALUES
        ("dora", "dora@amazon.com"),
        ("cansın", "cansın@google.com"),
        ("sencer", "sencer@bmw.com"),
        ("uras", "uras@mercedes.com"),
	    ("ares", "ares@porche.com");
        """)
    db.session.execute(drop_table)
    db.session.execute(users_table)
    db.session.execute(data)
    db.session.commit()

def find_emails(keyword):
    with app.app_context():
        query = text(f"""
        SELECT * FROM users WHERE username like '%{keyword}%';
        """)
        result = db.session.execute(query)
        user_emails = [(row[0], row[1]) for row in result]
        if not any(user_emails):
            user_emails = [("Not Found", "Not Found")]
        return user_emails

def insert_email(name,email):
    with app.app_context():
        query = text(f"""
        SELECT * FROM users WHERE username like '{name}'
        """)
        result = db.session.execute(query)
        response = ''
        if len(name) == 0 or len(email) == 0:
            response = 'Username or email can not be empty!!'
        elif not any(result):
            insert = text(f"""
            INSERT INTO users
            VALUES ('{name}', '{email}');
            """)
            result = db.session.execute(insert)
            db.session.commit()
            response = text(f"User {name} and {email} have been added successfully")
        else:
            response = text(f"User {name} already exist")
        return response
@app.route('/', methods=['GET', 'POST'])
def emails():
    with app.app_context():
        if request.method == 'POST':
            user_app_name = request.form['user_keyword']
            user_emails = find_emails(user_app_name)
            return render_template('emails.html', name_emails=user_emails, keyword=user_app_name,   show_result=True)
        else:
            return render_template('emails.html', show_result=False)
@app.route('/add', methods=['GET', 'POST'])
def add_email():
    with app.app_context():
        if request.method == 'POST':
            user_app_name = request.form['username']
            user_app_email = request.form['useremail']
            result_app = insert_email(user_app_name, user_app_email)
            return render_template('add-email.html', result_html=result_app, show_result=True)
        else:
            return render_template('add-email.html', show_result=False)


# - Add a statement to run the Flask application which can be reached from any host on port 80.
if __name__=='__main__':
    app.run(debug=True)
    #app.run(host='0.0.0.0', port=8080)

# https://flask-sqlalchemy.palletsprojects.com/en/2.x/config/
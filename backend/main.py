import sqlite3
import jwt
import datetime
import bcrypt
from flask import Flask, request, jsonify, request, redirect

app = Flask(__name__)

SECRET_KEY = "your_secret_key_here"

def init_db():
    conn = sqlite3.connect('users.db')
    c = conn.cursor()

    c.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        )
    ''')

    c.execute('''
        CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            content TEXT NOT NULL
        )
    ''')

    conn.commit()
    conn.close()


init_db()

def hash_password(password):
    salt = bcrypt.gensalt()
    hashed = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed.decode('utf-8')


def verify_password(password, hashed_password):
    return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))


def create_jwt_token(username):
    expiration = datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    payload = {'username': username, 'exp': expiration}
    return jwt.encode(payload, SECRET_KEY, algorithm='HS256')


def decode_jwt_token(token):
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
    except jwt.ExpiredSignatureError:
        return None
    except jwt.InvalidTokenError:
        return None


@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username, password = data.get('username'), data.get('password')

    if not username or not password:
        return jsonify({"message": "Username and password are required"}), 400

    hashed_password = hash_password(password)

    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    try:
        c.execute('INSERT INTO users (username, password) VALUES (?, ?)', (username, hashed_password))
        conn.commit()
    except sqlite3.IntegrityError:
        return jsonify({"message": "User already exists"}), 400
    finally:
        conn.close()

    return jsonify({"message": "User registered successfully"}), 201


@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username, password = data.get('username'), data.get('password')

    if not username or not password:
        return jsonify({"message": "Username and password are required"}), 400

    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute('SELECT password FROM users WHERE username = ?', (username,))
    user = c.fetchone()
    conn.close()

    if not user or not verify_password(password, user[0]):
        return jsonify({"message": "Invalid credentials"}), 401

    token = create_jwt_token(username)
    return jsonify({"message": "Login successful", "token": token}), 200


def get_logged_in_user():
    token = request.headers.get('Authorization')

    if not token:
        return None

    if token.startswith("Bearer "):
        token = token.split(" ")[1]

    decoded = decode_jwt_token(token)
    if decoded:
        return decoded['username']

    return None


@app.route('/add_note', methods=['POST'])
def add_note():
    username = get_logged_in_user()
    if not username:
        return jsonify({"message": "Unauthorized"}), 403

    data = request.get_json()
    content = data.get('content')

    if not content:
        return jsonify({"message": "Content is required"}), 400

    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute('INSERT INTO notes (username, content) VALUES (?, ?)', (username, content))
    conn.commit()
    conn.close()

    return jsonify({"message": "Note added successfully"}), 201

@app.before_request
def enforce_https():
    if not request.is_secure:
        url = request.url.replace("http://", "https://", 1)
        return redirect(url, code=301)

@app.route('/delete_note', methods=['DELETE'])
def delete_note():
    username = get_logged_in_user()
    if not username:
        return jsonify({"message": "Unauthorized"}), 403

    data = request.get_json()
    note_id = data.get('note_id')

    if not note_id:
        return jsonify({"message": "Note ID is required"}), 400

    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute('DELETE FROM notes WHERE id = ? AND username = ?', (note_id, username))
    conn.commit()
    deleted_rows = c.rowcount
    conn.close()

    if deleted_rows == 0:
        return jsonify({"message": "Note not found or unauthorized"}), 404

    return jsonify({"message": "Note deleted successfully"}), 200

@app.route('/edit_note/<int:note_id>', methods=['PUT'])
def edit_note(note_id):
    username = get_logged_in_user()
    if not username:
        return jsonify({"message": "Unauthorized"}), 403

    data = request.json
    new_content = data.get('content', '').strip()

    if not new_content:
        return jsonify({"error": "Note content cannot be empty"}), 400

    conn = sqlite3.connect('users.db')
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM notes WHERE id = ? AND username = ?", (note_id, username))
    note = cursor.fetchone()

    if not note:
        return jsonify({"error": "Note not found or unauthorized"}), 404

    # Update the note
    cursor.execute("UPDATE notes SET content = ? WHERE id = ? AND username = ?",
                   (new_content, note_id, username))

    conn.commit()
    conn.close()

    return jsonify({"message": "Note updated successfully"}), 200

@app.route('/notes', methods=['GET'])
def get_all_notes():
    username = get_logged_in_user()
    if not username:
        return jsonify({"message": "Unauthorized"}), 403

    conn = sqlite3.connect('users.db')
    c = conn.cursor()
    c.execute('SELECT id, content FROM notes WHERE username = ?', (username,))
    notes = [{'id': row[0], 'content': row[1]} for row in c.fetchall()]
    conn.close()

    return jsonify({"notes": notes}), 200


if __name__ == '__main__':
    app.run(ssl_context=('cert.pem', 'key.pem'), host='0.0.0.0', port=5000, debug=True)

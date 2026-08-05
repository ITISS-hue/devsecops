import sqlite3, os, pickle
#checking2
# SQL Injection
def get_user(username):
    conn = sqlite3.connect('test.db')
    cursor = conn.cursor()
    query = f"SELECT * FROM users WHERE username = '{username}'"  # Vulnerable
    cursor.execute(query)
    return cursor.fetchall()

# Command Injection
def run_ping(host):
    os.system(f"ping -c 1 {host}")  # Vulnerable

# Insecure Deserialization
def load_data(data):
    return pickle.loads(data)  # Vulnerable

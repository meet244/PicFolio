import sqlite3
import sys
import os
import sys
import json

config = None

def read_config():
    global config
    with open('config.json') as f:
        config = json.load(f)
    print("Config loaded")

read_config()

# Connect to the database (create it if it doesn't exist)
os.makedirs(f'{config["path"]}', exist_ok=True)
conn = sqlite3.connect(f'{config["path"]}/data.db')
# conn = sqlite3.connect('data.db')

# Create a cursor object
cursor = conn.cursor()

# Create assets table
cursor.execute('''
    CREATE TABLE shared (
        asset_id INTEGER NOT NULL,
        user TEXT NOT NULL,
        PRIMARY KEY (asset_id, user)
    )
''')

conn.commit()
# Close the connection
conn.close()

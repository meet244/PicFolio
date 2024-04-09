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

# take args from command line
username = sys.argv[1]+'/' if len(sys.argv) > 1 else ""

# Connect to the database (create it if it doesn't exist)
os.makedirs(f'{config["path"]}/{username}', exist_ok=True)
conn = sqlite3.connect(f'{config["path"]}/{username}/data.db')
# conn = sqlite3.connect('data.db')

# Create a cursor object
cursor = conn.cursor()

# Create assets table
cursor.execute('''CREATE TABLE assets
            (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
            name TEXT NOT NULL, 
            format INTEGER NOT NULL, 
            created DATE NOT NULL,
            blurry INTEGER DEFAULT NULL, 
            deleted DATE DEFAULT 0 NOT NULL, 
            compress INTEGER DEFAULT NULL,
            duration TEXT DEFAULT NULL,
            liked INTEGER DEFAULT NULL,
            shared INTEGER DEFAULT NULL,
            city TEXT DEFAULT NULL,
            state TEXT DEFAULT NULL,
            country TEXT DEFAULT NULL)''')

# create tags table
cursor.execute('''CREATE TABLE tags
            (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
            tag TEXT NOT NULL UNIQUE)''')

# Create asset_tags table
cursor.execute('''CREATE TABLE asset_tags
            (asset_id INTEGER NOT NULL, 
            tag_id INTEGER NOT NULL, 
            PRIMARY KEY (asset_id, tag_id),
            FOREIGN KEY (asset_id) REFERENCES assets(id),
            FOREIGN KEY (tag_id) REFERENCES tags(id))''')

# Create table faces
cursor.execute('''CREATE TABLE faces
            (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
            name TEXT NOT NULL)''')

# Create table asset_faces
cursor.execute('''CREATE TABLE asset_faces
            (asset_id INTEGER NOT NULL, 
            face_id INTEGER NOT NULL, 
            x INTEGER,
            y INTEGER,
            w INTEGER,
            h INTEGER,
            verified INTEGER DEFAULT 0 NOT NULL,
            FOREIGN KEY (asset_id) REFERENCES assets(id),
            FOREIGN KEY (face_id) REFERENCES faces(id))''')

# Create table duplicates
cursor.execute('''CREATE TABLE duplicates
            (asset_id INTEGER NOT NULL,
            asset_id2 INTEGER NOT NULL,
            PRIMARY KEY (asset_id, asset_id2),
            FOREIGN KEY (asset_id) REFERENCES assets(id),
            FOREIGN KEY (asset_id2) REFERENCES assets(id))''')


# Create table album
cursor.execute('''CREATE TABLE album
            (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            name TEXT NOT NULL,
            cover INTEGER DEFAULT NULL,
            start DATE DEFAULT NULL,
            end DATE DEFAULT NULL,
            location TEXT DEFAULT NULL)''')

# Create table album_assets
cursor.execute('''CREATE TABLE album_assets
            (album_id INTEGER NOT NULL,
            asset_id INTEGER NOT NULL,
            PRIMARY KEY (album_id, asset_id),
            FOREIGN KEY (album_id) REFERENCES album(id),
            FOREIGN KEY (asset_id) REFERENCES assets(id))''')


with open("ram_tag_list.txt", "r") as file:
    # Perform operations on the file
    # For example, read the contents of the file
    file_contents = file.readlines()
    for i in (file_contents):
        i = i.replace("\n","")
        cursor.execute("INSERT INTO tags (tag) VALUES (?)", (i,))

# #TODO: remove this
# cursor.execute("INSERT INTO faces (name) VALUES ('alia')")
# cursor.execute("INSERT INTO faces (name) VALUES ('anushka')")
# cursor.execute("INSERT INTO faces (name) VALUES ('disha')")
# cursor.execute("INSERT INTO faces (name) VALUES ('karan')")
# cursor.execute("INSERT INTO faces (name) VALUES ('kiara')")
# cursor.execute("INSERT INTO faces (name) VALUES ('rakul')")
# cursor.execute("INSERT INTO faces (name) VALUES ('sidharth')")
# cursor.execute("INSERT INTO faces (name) VALUES ('varun')")



# Close the connection
conn.close()

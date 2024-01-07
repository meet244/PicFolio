import sqlite3

# Connect to the database (create it if it doesn't exist)
conn = sqlite3.connect('data.db')

# Create a cursor object
cursor = conn.cursor()

# Create assets table
cursor.execute('''CREATE TABLE assets
            (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
            name TEXT NOT NULL, 
            format INTEGER NOT NULL, 
            created DATE NOT NULL,
            blurry INTEGER DEFAULT NULL, 
            deleted INTEGER DEFAULT 0 NOT NULL, 
            compressed INTEGER DEFAULT NULL)''')

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
            x INTEGER NOT NULL,
            y INTEGER NOT NULL,
            w INTEGER NOT NULL,
            h INTEGER NOT NULL,
            PRIMARY KEY (asset_id, face_id),
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
            uuid TEXT NOT NULL UNIQUE,
            name TEXT NOT NULL,
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

#TODO: remove this
cursor.execute("INSERT INTO faces (name) VALUES ('alia')")
cursor.execute("INSERT INTO faces (name) VALUES ('anushka')")
cursor.execute("INSERT INTO faces (name) VALUES ('disha')")
cursor.execute("INSERT INTO faces (name) VALUES ('karan')")
cursor.execute("INSERT INTO faces (name) VALUES ('kiara')")
cursor.execute("INSERT INTO faces (name) VALUES ('rakul')")
cursor.execute("INSERT INTO faces (name) VALUES ('sidharth')")
cursor.execute("INSERT INTO faces (name) VALUES ('varun')")


conn.commit()
# Close the connection
conn.close()

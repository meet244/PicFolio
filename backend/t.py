import os
import sqlite3
# from deepface import DeepFace


import sqlite3

# Connect to the database
conn = sqlite3.connect(r'E:\Picfolio\meet244\data.db')
cursor = conn.cursor()

# Define the asset_id and tag_id
asset_id = 338
tag_id = 3562

# Insert into the asset_tags table
cursor.execute("INSERT INTO asset_tags (asset_id, tag_id) VALUES (?, ?)", (asset_id, tag_id))

# Commit the transaction
conn.commit()

# Close the connection
conn.close()

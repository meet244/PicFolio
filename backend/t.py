import os
import sqlite3
# from deepface import DeepFace


import sqlite3

# Connect to the database
conn = sqlite3.connect(r'E:\Picfolio\meet244\data.db')
cursor = conn.cursor()

# Define the asset_id and tag_id
# asset_id = 338
# tag_id = 3562

# Insert into the asset_tags table
cursor.execute("""
SELECT t.tag, COUNT(*) AS count
FROM asset_tags AS at
JOIN tags AS t ON at.tag_id = t.id
GROUP BY at.tag_id
ORDER BY count DESC LIMIT 10
""")

print(cursor.fetchall())

# Commit the transaction
# conn.commit()

# Close the connection
conn.close()

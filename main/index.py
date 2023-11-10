from flask import Flask, request
from PIL import Image
from PIL.ExifTags import TAGS
import os
import uuid
import sqlite3
from datetime import datetime

# create the database file
connection = sqlite3.connect('data.db')
cursor = connection.cursor()
create_table_sql = """
CREATE TABLE IF NOT EXISTS asset (
name TEXT PRIMARY KEY UNIQUE NOT NULL,
date DateTime NOT NULL,
isphoto BOOL NOT NULL DEFAULT TRUE
);
"""
cursor.execute(create_table_sql)
connection.commit()
connection.close()


app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload():
    # Check if the post request has the file part
    if 'file' not in request.files:
        return 'No image uploaded'

    file = request.files['file']
    format = file.filename.split('.')[-1]
    isPhoto = True

    #check image format
    if format in ['jpg', 'jpeg','webp', 'png']:
        pass
    elif format in ['mp4', 'mkv']:
        isPhoto = False
    else:
        return 'Invalid format'

    # create a folder of today's year inside that folder of month and inside that folder of date then save the image there
    id = str(uuid.uuid4())
    id = uuid.uuid4().hex
    today = datetime.now()
    today_folder = os.path.join(str(today.year), str(today.month), str(today.day))

    # inser data to db
    add_row = f"INSERT INTO asset (name, date, isphoto) VALUES (?, ?, ?);"
    connection = sqlite3.connect('data.db')
    cursor = connection.cursor()
    # check_table(cursor)
    cursor.execute(add_row, (id, today.strftime('%Y-%m-%d %H:%M:%S'), isPhoto))
    connection.commit()
    connection.close()

    os.makedirs(today_folder, exist_ok=True)
    file.save(os.path.join(today_folder, id+'.'+format))

    return 'Image uploaded and saved successfully'



if __name__ == '__main__':
    app.run(debug=True)

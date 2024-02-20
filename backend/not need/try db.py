from flask import Flask, request, send_file, jsonify
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
    cursor.execute(add_row, (id+'.'+format, today.strftime('%Y-%m-%d %H:%M:%S'), isPhoto))
    connection.commit()
    connection.close()

    os.makedirs(today_folder, exist_ok=True)
    file.save(os.path.join(today_folder, id+'.'+format))

    return 'Image uploaded and saved successfully'

@app.route('/delete', methods=['POST'])
def delete():
    d = request.form.get('date') # 2023-12-25
    a = request.form.get('asset')
    if(not(a and d)):
        return 'Invalid request'
    path = ""
    for i in d.split("-"):
        path = os.path.join(path, i)
    print(path)
    if(os.path.exists(os.path.join(path,a))):

        connection = sqlite3.connect('data.db')
        cursor = connection.cursor()
        
        # remove data from db
        delete_row = f"DELETE FROM asset WHERE name = '{a}'"
        connection = sqlite3.connect('data.db')
        cursor = connection.cursor()
        cursor.execute(delete_row)
        connection.commit()
        connection.close()
    
        os.remove(os.path.join(path,a))
        return "ok"
    return "not found"

@app.route('/view/<date>/<asset>')
def view(date,asset):
    path = ""
    for i in date.split("-"):
        path = os.path.join(path, i)
    path = os.path.join(path,asset)
    if(os.path.exists(path)):
        return send_file(path)
    return 'file not found'

@app.route('/list')
def listOut():
    # get list of all dates in sorted form and all unique ones
    connection = sqlite3.connect('data.db')
    cursor = connection.cursor()
    cursor.execute("SELECT DISTINCT date FROM asset ORDER BY date DESC")
    dates = cursor.fetchall()
    final_dates = list(set(date[0].split()[0] for date in dates))

    return jsonify(final_dates)

if __name__ == '__main__':
    app.run(debug=True)
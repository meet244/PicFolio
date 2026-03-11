from flask import Flask, jsonify, request, send_file, render_template
# import flask_cors
import json
import sqlite3
import threading
import random
import os
import uuid
import flask_cors
from PIL import Image, ExifTags
# import background_funs
from waitress import serve
import time
from datetime import datetime, timedelta
import sys
import threading
import os
from dotenv import load_dotenv
import google.generativeai as genai
from moviepy.video.io import VideoFileClip
import gemini
import nltk
from nltk.corpus import wordnet as wn
from geopy.geocoders import Nominatim
import shutil

nltk.download('wordnet')
load_dotenv()

# LOAD GEMINI API
genai.configure(api_key=os.getenv('Gemini'))
model = genai.GenerativeModel('gemini-pro')

tags = None
# with open("backend/ram_tag_list.txt", "r") as file:
#     tags = file.read()

config = None

def read_config():
    global config
    if os.path.exists('config.json'):
        with open('config.json') as f:
            config = json.load(f)
        # Ensure passwords key exists for backward compatibility
        if 'passwords' not in config:
            config['passwords'] = []
    else:
        config = {"users": ["family"], "path": "", "passwords": ["family"]}
        save_config()
    print("Config loaded")
def save_config():
    global config
    with open('config.json', 'w') as f:
        json.dump(config, f)
    print("Config saved")

read_config()
users = config['users']
conn = None
cursor = None

def open_dbs(username):
    global config, conn, cursor

    if not os.path.exists(f'{config["path"]}/{username}/data.db'):
        os.system(f'python backend/dbmake.py {username}')
    conn = sqlite3.connect(f'{config["path"]}/{username}/data.db', check_same_thread=False)
    cursor = conn.cursor()

if users != []:
    open_dbs(users[0])

app = Flask(__name__)
flask_cors.CORS(app)

# # Error handler for 404 Not Found
# @app.errorhandler(404)
# def not_found_error(error):
#     return jsonify({'error': 'Not Found'}), 404

# # Error handler for 500 Internal Server Error
# @app.errorhandler(500)
# def internal_server_error(error):
    # return jsonify({'error': 'Internal Server Error'}), 500

# hello world
@app.route('/')
def hello():
    return "Hello There!"




# --------------- HIGHER ACCESS APIS --------------- 

# Create user
@app.route('/api/user/create', methods=['POST'])
def create_user():
    # Logic to create user
    try:
        username = request.form['username']
        password = request.form['password']
    except:
        return jsonify('Improper data sent')
    
    if username in users:
        return jsonify('User already exists')
    
    users.append(username)
    config['users'] = users
    # Ensure passwords key exists
    if 'passwords' not in config:
        config['passwords'] = []
    config['passwords'].append(password)
    save_config()

    return jsonify('true')

# Rename user
@app.route('/api/user/rename/<string:username>/<string:new_username>', methods=['POST'])
def rename_user(username, new_username):
    # Logic to rename user
    if username not in users:
        return jsonify({'error': 'User not found'}), 404
    elif new_username in users:
        return jsonify({'error': 'User already exists'}), 400
    else:
        users.remove(username)
        users.append(new_username)
        config['users'] = users
        save_config()
        os.rename(f'{username}', f'{new_username}')
        return jsonify({'message': 'User renamed successfully'})

# Sign in user
@app.route('/api/user/auth', methods=['POST'])
def auth_user():
    # Logic to authenticate user
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found')
    except:
        return jsonify('User not found')
    
    try:
        password = request.form['password']
    except:
        return jsonify('Incorrect password')
    
    if username == None or password == None:
        return jsonify('User not found')
    
    ind = users.index(username)
    if config['passwords'][ind] != password:
        return jsonify('Incorrect password')
    
    return jsonify('true')

# Fetch users
@app.route('/api/users', methods=['GET'])
def get_users():
    # Logic to get users
    return jsonify(users)

# Delete user
@app.route('/api/user/delete/<string:username>', methods=['DELETE'])
def delete_user(username):
    # Logic to delete user
    if username not in users:
        return jsonify({'error': 'User not found'}), 404
    users.remove(username)
    config['users'] = users
    save_config()
    shutil.rmtree(f'{config["path"]}/{username}')
    return jsonify({'message': 'User deleted successfully'})





# --------------- CURD ASSETS APIS --------------- 

# upload photos/videos
@app.route('/api/upload', methods=['POST'])
def upload():
    # Logic to handle photo/video uploaded in form
    username = ""
    try:
        if request.form['username'] not in users:
            return jsonify({'error': 'User not found'}), 404
        username = request.form['username']
    except:
        return jsonify({'error': 'User not found'}), 404
    if username == None:
        return jsonify({'error': 'User not found'}), 404
    print(username)
    asset = request.files['asset']
    compress = None
    try:
        compress = request.form['compress']
    except:pass
    open_dbs(username)
    print(asset.filename)
    print(compress)

    allowed_extensions = {'png', 'jpg', 'jpeg', 'avif', 'heic', 'ttif', 'webp', 'jfif', 'mp4', 'mov', 'avi', 'webm', 'flv', 'wmv', 'mkv'}
    if asset.filename.split('.')[-1].lower() in allowed_extensions:
        # Update the sqlite database with the photo/video details
        cursor.execute("INSERT INTO assets (name, format, created, compress) VALUES (?, ?, ?, ?)", (asset.filename, asset.filename.split(".")[-1].lower(), datetime.now(), compress!=None))
        # conn.commit()
        cursor.execute("SELECT MAX(id) FROM assets")
        id = cursor.fetchone()[0]

        # Save the photo/video to the storage
        # Create the folder if it doesn't exist
        if not os.path.exists(f'{config["path"]}/{username}/temp/'):
            os.makedirs(f'{config["path"]}/{username}/temp/')
        asset.save(f'{config["path"]}/{username}/temp/'+str(id)+"."+asset.filename.split(".")[-1].lower())

        longitude = None
        latitude = None

        date_time = datetime.now()
        if asset.filename.split(".")[-1].lower() in ['png', 'jpg', 'jpeg', 'webp']:
            img = Image.open(f'{config["path"]}/{username}/temp/'+str(id)+"."+asset.filename.split(".")[-1].lower())
            exif_data = img.getexif()
            for tag_id in exif_data:
                tag = ExifTags.TAGS.get(tag_id, tag_id)
                data = exif_data.get(tag_id)

                # get the date and time from exif data using tag
                if tag == 'DateTimeOriginal':
                    date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                    print(f"Date and Time: {date_time}")
                elif tag == 'DateTimeDigitized':
                    date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                    print(f"Date and Time: {date_time}")
                elif tag == 'DateTime':
                    date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                    print(f"Date and Time: {date_time}")
                elif tag == 'GPSLatitude':
                    latitude = data
                elif tag == 'GPSLongitude':
                    longitude = data

            
            img.close()
        else:
            vid = VideoFileClip(f'{config["path"]}/{username}/temp/'+str(id)+"."+asset.filename.split(".")[-1].lower())
            if vid.reader.infos['creation_time'] != None:
                date_time = datetime.strptime(vid.reader.infos['creation_time'], '%Y-%m-%d %H:%M:%S')

            duration = vid.duration
            hours = int(duration // 3600)
            minutes = int((duration % 3600) // 60)
            seconds = int(duration % 60)
            seconds = str(seconds).zfill(2)
            file = file[:-4]
            if hours != 0:
                duration = f"{hours}:{minutes}:{seconds}"
            else:
                duration = f"{minutes}:{seconds}"

            cursor.execute("UPDATE assets SET duration = ? WHERE id = ?", (duration, id,))

            # get lat and long from exif data of the video
            if vid.reader.infos['gps_latitude'] != None:
                latitude = vid.reader.infos['gps_latitude']
            if vid.reader.infos['gps_longitude'] != None:
                longitude = vid.reader.infos['gps_longitude']

            vid.close()

        if latitude != None and longitude != None:
            geolocator = Nominatim(user_agent="geoapiExercises")
            location = geolocator.reverse(f"{latitude}, {longitude}")
            print(location)
            cursor.execute("UPDATE assets SET city = ?, state = ?, country = ? WHERE id = ?", (location.raw['address']['city'], location.raw['address']['state'], location.raw['address']['country'], id,))

        # update the date and time in the database
        cursor.execute("UPDATE assets SET created = ? WHERE id = ?", (date_time, id,))
        conn.commit()
                
        return jsonify({'message': 'Uploaded successfully'})
    else:
        return jsonify({'error': 'Invalid file type'}), 400

# delete a photo
@app.route('/api/delete/<string:username>/<string:ids>', methods=['DELETE'])
def delete_photo(username, ids):
    # Logic to delete the photo from the database or storage (master and preview)
    if username not in users:
        return jsonify('User not found'), 404
    try:
        ids = ids.split(',')
    except:
        return jsonify('Bad request'), 400
    
    print(username)
    open_dbs(username)
    success= []
    fail = []
    for i in ids:
        cursor.execute("SELECT deleted,created,format from assets where id=?", (i,))
        deleted, created, format = cursor.fetchone()
        if deleted == None or deleted == 0:
            delete_date = datetime.now() + timedelta(days=90)
            cursor.execute("UPDATE assets SET deleted = ? WHERE id = ?", (delete_date, i,))

            # cursor.execute("DELETE FROM duplicates WHERE asset_id = ? OR asset_id2 = ?", (i, i,))

            # check if the photo exists
            if cursor.rowcount != 0:success.append(i)
            else:fail.append(i)
        else:
            # convert created to datetime object
            try:
                created = datetime.strptime(created, '%Y-%m-%d %H:%M:%S.%f')
            except:
                created = datetime.strptime(created, '%Y-%m-%d %H:%M:%S')

            if format.lower() in ['png', 'jpg', 'jpeg', 'avif', 'heic', 'ttif', 'webp']:
                os.remove(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(i)+'.png')
                os.remove(f'{config["path"]}/{username}/preview/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(i)+'.webp')
            else:
                os.remove(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(i)+'.mp4')
                os.remove(f'{config["path"]}/{username}/preview/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(i)+'.gif')

            cursor.execute("DELETE FROM assets WHERE id = ?", (i,))
            # check if the photo exists
            if cursor.rowcount != 0:success.append(i)
            else:fail.append(i)

    conn.commit()
    return jsonify({"success":success, "failed":fail})

# restore a photo
@app.route('/api/restore', methods=['POST'])
def restore_photo():
    # Logic to restore the photo from the database or storage
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found'), 404
    except:
        return jsonify('username not found'),404
    
    try:
        ids = request.form['ids']
        ids = ids.split(',')
    except Exception as e:
        print(e)
        return jsonify('Bad request'), 400
    open_dbs(username)
    success= []
    fail = []
    for i in ids:
        cursor.execute("UPDATE assets SET deleted = ? WHERE id = ?", (0, i,)) # 0-> None on #DBUPDATE
        # check if the photo exists
        if cursor.rowcount != 0:success.append(i)
        else:fail.append(i)
    conn.commit()
    return jsonify({"success":success, "failed":fail})

# get a photo/video preview
@app.route('/api/preview/<string:username>/<int:photo_id>/<int:yyyy>/<int:mm>/<int:dd>', methods=['GET'])
def preview_asset(username,photo_id,yyyy,mm,dd):
    # Logic to get the preview photo/video from the database or storage

    if username not in users:
        return jsonify('User not found'), 404

    try:
        return send_file(f'{config["path"]}/{username}/preview/'+str(yyyy)+'/'+str(mm)+'/'+str(dd)+'/'+str(photo_id)+'.webp', mimetype=f'image/webp')
    except:
        try:
            return send_file(f'{config["path"]}/{username}/preview/'+str(yyyy)+'/'+str(mm)+'/'+str(dd)+'/'+str(photo_id)+'.gif', mimetype=f'image/gif')
        except:
            try:
                return send_file(f'{config["path"]}/{username}/preview/'+str(yyyy)+'/'+str(mm)+'/'+str(dd)+'/'+str(photo_id)+'.mp4', mimetype=f'video/mp4')
            except:
                return jsonify('Preview not found'), 404

@app.route('/api/preview/<string:username>/<int:photo_id>', methods=['GET'])
def preview_asset2(username,photo_id):

    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)

    done = False
    tries = 10
    while not done and tries > 0:
        try:
            cursor.execute("SELECT created FROM assets WHERE id = ?", (photo_id,))
            # check if the photo exists
            # if cursor.rowcount == 0:
            #     return jsonify('Photo not found'), 404

            date_time = cursor.fetchone()[0]
            if date_time == None:
                return jsonify('Photo not found'), 404
            done = True
        except Exception:
            # print(e)
            print("Recursive cursor usage")
            tries-=1
            time.sleep(0.2)
            continue

    # convert date_time to datetime object
    if date_time == None : return jsonify("Date Note Found"), 400
    try:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

    try:
        return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.webp', mimetype=f'image/webp')
    except:
        try:
            return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.gif', mimetype=f'image/gif',)
        except:
            return jsonify('Preview not found'), 404

# get a photo/video original
@app.route('/api/asset/<string:username>/<int:photo_id>/<int:yyyy>/<int:mm>/<int:dd>', methods=['GET'])
def get_asset(username,photo_id, yyyy, mm, dd):
    # Logic to get the photo/video from the database or storage
    
    if username not in users:
        return jsonify('User not found'), 404

    try:
        return send_file(f'{config["path"]}/{username}/master/'+str(yyyy)+'/'+str(mm)+'/'+str(dd)+'/'+str(photo_id)+'.png', mimetype=f'image/png')
    except:
        try:
            return send_file(f'{config["path"]}/{username}/master/'+str(yyyy)+'/'+str(mm)+'/'+str(dd)+'/'+str(photo_id)+'.mp4', mimetype=f'video/mp4')
        except:
            return jsonify('Photo not found'), 404

    open_dbs(username)

    cursor.execute("SELECT created,format FROM assets WHERE id = ?", (photo_id,))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    
    date_time, format = cursor.fetchone()
    # convert date_time to datetime object
    try:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

    if format == "mp4":
        return send_file(f'{config["path"]}/{username}/master/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.'+format, mimetype=f'video/{format}')
    return send_file(f'{config["path"]}/{username}/master/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.png', mimetype=f'image/png')

@app.route('/api/asset/<string:username>/<int:photo_id>', methods=['GET'])
def get_asset2(username,photo_id):
    # Logic to get the photo/video from the database or storage
    
    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)
    
    done = False
    tries = 10
    while not done and tries > 0:
        try:
            cursor.execute("SELECT created FROM assets WHERE id = ?", (photo_id,))

            # check if the photo exists
            # if cursor.rowcount == 0:
            #     return jsonify('Photo not found'), 404

            date_time = cursor.fetchone()[0]
            if date_time == None:
                return jsonify('Photo not found'), 404
            done = True
        except Exception:
            # print(e)
            print("Recursive cursor usage")
            tries-=1
            time.sleep(0.2)
            continue

    try:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

    if format == "mp4":
        return send_file(f'{config["path"]}/{username}/master/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.'+format, mimetype=f'video/{format}')
    return send_file(f'{config["path"]}/{username}/master/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.png', mimetype=f'image/png')

# get a list of photos/videos
@app.route('/api/list/general', methods=['POST'])
def get_list():
    # Logic to get the list of photos/videos from the database or storage
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    
    try:
        page = int(request.form['page'])  # start from 0
    except:
        return jsonify('page not found'),404
    
    print(username)
    open_dbs(username)

    cursor.execute("SELECT DATE(created), GROUP_CONCAT(id), GROUP_CONCAT(IFNULL(duration, '')) FROM assets WHERE deleted = 0 AND blurry IS NOT NULL GROUP BY DATE(created) ORDER BY DATE(created) DESC LIMIT 4 OFFSET {}".format(page*4))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    result = cursor.fetchall()
    # print(result)
    
    formatted_result = []
    for row in result:
        ids = []
        row1 = row[1].split(',')
        row2 = row[2].split(',')
        for i in range(len(row1)):
            if row2[i] != "":
                id_int = [int(row1[i]),None,row2[i]]
            else:
                id_int = [int(row1[i])]
            ids.append(id_int)
        formatted_result.append([row[0], ids])
        # for i in range(len(row[1].split(','))):
        #     if row2[i] == "mp4":
        #         formatted_result.append([row[0], [int(row1[i]),None, "3:25"]])
        #     formatted_result.append([row[0], [int(row1[i])]])
    # formatted_result = [{row[0]: [int(id) for id in row[1].split(',')] for row in result}]
    return jsonify(formatted_result)

# list of only image ids
@app.route('/api/list/<string:username>', methods=['GET'])
def get_list_user(username):
    # Logic to get the list of photos/videos from the database or storage
    if username not in users:
        return jsonify('User not found'), 404
    print(username)
    open_dbs(username)

    cursor.execute("SELECT id FROM assets WHERE deleted = 0 GROUP BY DATE(created)")
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    result = cursor.fetchall()
    formatted_result = [id[0] for id in result]
    return jsonify(formatted_result)


def start_this():
    # while True: #todo: remove this
    threading.Thread(target=run_background_script, daemon=True).start()
    # print("Server started")
    serve(app, host="0.0.0.0", port=7251)
    # app.run(host="0.0.0.0", port=7251, debug=False) # multiple bg threads here
    # app.run(port=7251, debug=False) # multiple bg threads here

def run_background_script():
        os.system('python backend/background.py')

if __name__ == '__main__':    # remove if karan is running
    start_this()

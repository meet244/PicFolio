from flask import Flask, jsonify, request, send_file, render_template
from flask_caching import Cache
# import flask_cors
import json
import sqlite3
import threading
import random
import os
import uuid
import flask_cors
from PIL import Image, ExifTags
import cv2
import background_funs
from waitress import serve
import time
from datetime import datetime, timedelta
import sys
import threading
import os
from dotenv import load_dotenv
import google.generativeai as genai
from moviepy.video.io.VideoFileClip import VideoFileClip
import gemini
import nltk
from nltk.corpus import wordnet as wn
import shutil
import subprocess
import ctypes
import user_store
from rapidfuzz import process, fuzz
import pickle
import re
from sentence_transformers import SentenceTransformer, util
import torch

nltk.download('wordnet')
load_dotenv()

# LOAD GEMINI API
genai.configure(api_key=os.getenv('Gemini'))
model = genai.GenerativeModel('gemini-pro')

tags = None
with open("backend/ram_tag_list.txt", "r") as file:
    tags = file.read()

config = None  # for storing the config
config_mtime = None  # for checking if the config file has been modified


def read_config():
    global config, config_mtime
    if os.path.exists('config.json'):
        with open('config.json') as f:
            config = json.load(f)
    else:
        config = {"path": ""}
        save_config()

    config.setdefault('path', "")
    try:
        config_mtime = os.path.getmtime('config.json')
    except FileNotFoundError:
        config_mtime = None
    print("Config loaded")


def save_config():
    global config, config_mtime
    with open('config.json', 'w') as f:
        json.dump({"path": config.get("path", "")}, f)
    try:
        config_mtime = os.path.getmtime('config.json')
    except FileNotFoundError:
        config_mtime = None
    print("Config saved")


def ensure_storage_path():
    global config_mtime
    try:
        current_mtime = os.path.getmtime('config.json')
    except FileNotFoundError:
        current_mtime = None

    if current_mtime != config_mtime:
        read_config()

    return bool(config.get('path'))


def _to_float(value):
    try:
        return float(value)
    except (TypeError, ValueError, ZeroDivisionError):
        if hasattr(value, 'numerator') and hasattr(value, 'denominator'):
            return float(value.numerator) / float(value.denominator)
        return None


def _dms_to_decimal(coords):
    if coords is None:
        return None
    if isinstance(coords, (list, tuple)):
        parts = [_to_float(part) for part in coords]
        if not parts:
            return None
        while len(parts) < 3:
            parts.append(0.0)
        degrees, minutes, seconds = parts[:3]
        if None in (degrees, minutes, seconds):
            return None
        return degrees + minutes / 60 + seconds / 3600
    return _to_float(coords)


def _apply_ref(value, ref):
    if value is None or not ref:
        return value
    ref = ref.upper()
    if ref in ('S', 'W'):
        return -abs(value)
    return abs(value)


def refresh_user_cache():
    """
    Refresh in-memory user list from the persistent store.
    """
    global users
    if not ensure_storage_path():
        users = []
        return
    try:
        users = user_store.list_users(config['path'])
    except Exception as exc:
        print(f"Unable to refresh user cache: {exc}")
        users = []


def add_user_record(username, password):
    if not ensure_storage_path():
        raise ValueError("Storage path is not configured.")
    user_store.add_user(config['path'], username, password)
    refresh_user_cache()


def remove_user_record(username):
    if not ensure_storage_path():
        raise ValueError("Storage path is not configured.")
    user_store.remove_user(config['path'], username)
    refresh_user_cache()


def get_user_password(username):
    if not ensure_storage_path():
        return None
    return user_store.get_user_password(config['path'], username)

read_config()
users = []
conn = None
cursor = None
background_process = None

refresh_user_cache()

def open_dbs(username):
    global config, conn, cursor

    if not ensure_storage_path():
        raise ValueError("Storage path is not configured.")

    if not os.path.exists(f'{config["path"]}/{username}/data.db'):
        os.system(f'python backend/dbmake.py {username}')
    conn = sqlite3.connect(f'{config["path"]}/{username}/data.db', check_same_thread=False, timeout=30)
    cursor = conn.cursor()

if users != []:
    open_dbs(users[0])

app = Flask(__name__)
flask_cors.CORS(app)

# Configure Cache
cache = Cache(app, config={
    'CACHE_TYPE': 'FileSystemCache',
    'CACHE_DIR': 'backend/.flask_cache',
    'CACHE_DEFAULT_TIMEOUT': 300
})

def make_cache_key(*args, **kwargs):
    # Create a key based on the request path and form data (for POST requests)
    key = request.path
    if request.method == 'POST':
        for k in sorted(request.form.keys()):
            key += str(k) + str(request.form[k])
    return key

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
    
    try:
        add_user_record(username, password)
    except Exception as exc:
        print(f"Failed to add user {username}: {exc}")
        return jsonify('Unable to create user'), 500

    cache.clear()
    return jsonify('true')



# Sign in user
@app.route('/api/user/auth', methods=['POST'])
def auth_user():
    # Logic to authenticate user
    try:
        username = request.form['username']
    except:
        return jsonify('User not found')
    
    if username not in users:
        refresh_user_cache()
        if username not in users:
            return jsonify('User not found')
    
    try:
        password = request.form['password']
    except:
        return jsonify('Incorrect password')
    
    if username == None or password == None:
        return jsonify('User not found')
    
    stored_password = get_user_password(username)
    if stored_password is None or stored_password != password:
        return jsonify('Incorrect password')
    
    return jsonify('true')

# Fetch users
@app.route('/api/users', methods=['GET'])
@cache.cached(timeout=60)
def get_users():
    # Logic to get users
    refresh_user_cache()
    return jsonify(users)

# Delete user
@app.route('/api/user/delete/<string:username>', methods=['DELETE'])
def delete_user(username):
    # Logic to delete user
    if username not in users:
        return jsonify({'error': 'User not found'}), 404


    # stop the background script
    stop_background_script()

    # remove the database and the user folder
    shutil.rmtree(f'{config["path"]}/{username}', ignore_errors=True)

    # remove from persistent store
    try:
        remove_user_record(username)
    except Exception as exc:
        print(f"Failed to remove user {username} from store: {exc}")

    # restart background script
    run_background_script()

    cache.clear()
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
        latitude_ref = None
        longitude_ref = None

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
                    latitude = _dms_to_decimal(data)
                elif tag == 'GPSLatitudeRef':
                    latitude_ref = data
                elif tag == 'GPSLongitude':
                    longitude = _dms_to_decimal(data)
                elif tag == 'GPSLongitudeRef':
                    longitude_ref = data

            
            img.close()
        else:
            vid = VideoFileClip(f'{config["path"]}/{username}/temp/'+str(id)+"."+asset.filename.split(".")[-1].lower())
            if 'creation_time' in vid.reader.infos and vid.reader.infos['creation_time'] is not None:
                try:
                    date_time = datetime.strptime(vid.reader.infos['creation_time'], '%Y-%m-%d %H:%M:%S')
                except ValueError:
                    # Try parsing with timezone if present or different format
                    try:
                        date_time = datetime.strptime(vid.reader.infos['creation_time'], '%Y-%m-%dT%H:%M:%S.%fZ')
                    except:
                        pass

            duration = vid.duration
            hours = int(duration // 3600)
            minutes = int((duration % 3600) // 60)
            seconds = int(duration % 60)
            seconds = str(seconds).zfill(2)
            if hours != 0:
                duration = f"{hours}:{minutes}:{seconds}"
            else:
                duration = f"{minutes}:{seconds}"

            cursor.execute("UPDATE assets SET duration = ? WHERE id = ?", (duration, id,))

            # get lat and long from exif data of the video
            if 'gps_latitude' in vid.reader.infos and vid.reader.infos['gps_latitude'] is not None:
                latitude = _to_float(vid.reader.infos['gps_latitude'])
            if 'gps_longitude' in vid.reader.infos and vid.reader.infos['gps_longitude'] is not None:
                longitude = _to_float(vid.reader.infos['gps_longitude'])

            vid.close()

        latitude = _apply_ref(latitude, latitude_ref)
        longitude = _apply_ref(longitude, longitude_ref)

        if latitude is not None and longitude is not None:
            cursor.execute("UPDATE assets SET latitude = ?, longitude = ? WHERE id = ?", (latitude, longitude, id,))

        # update the date and time in the database
        cursor.execute("UPDATE assets SET created = ? WHERE id = ?", (date_time, id,))
        conn.commit()
                
        cache.clear()
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
    cache.clear()
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
    cache.clear()
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

    cursor.execute("SELECT created,format FROM assets WHERE id = ?", (photo_id,))

    date_time, format = cursor.fetchone()

    if date_time is None:
        return jsonify('Photo not found'), 404

    # convert date_time to datetime object
    try:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

    # if video, return gif
    if format == "mp4":
        return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.gif', mimetype=f'image/gif',)
    else:
        return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.webp', mimetype=f'image/webp')


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
    
    cursor.execute("SELECT created,format FROM assets WHERE id = ?", (photo_id,))
    
    date_time, format = cursor.fetchone()
    if date_time is None:
        return jsonify('Photo not found'), 404

    try:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

    if format == "mp4":
        return send_file(f'{config["path"]}/{username}/master/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.'+format, mimetype=f'video/{format}')
    return send_file(f'{config["path"]}/{username}/master/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.png', mimetype=f'image/png')

# get a list of photos/videos
@app.route('/api/list/general', methods=['POST'])
@cache.cached(key_prefix=make_cache_key)
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
@cache.cached()
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

# get asset details
@app.route('/api/details/<string:username>/<int:photo_id>', methods=['GET'])
@cache.cached()
def get_details(username, photo_id):
    # Logic to get the photo/video from the database or storage

    if username not in users:
        return jsonify('User not found'), 404
    
    open_dbs(username)

    # Fetch tags with error handling
    try:
        cursor.execute("SELECT tags.tag FROM asset_tags INNER JOIN tags ON asset_tags.tag_id = tags.id WHERE asset_tags.asset_id = ?", (photo_id,))
        tags = [tag[0] for tag in cursor.fetchall()]
    except Exception as e:
        app.logger.error(f"Error fetching tags for asset {photo_id}: {str(e)}")
        tags = []  # Default to empty list if tags query fails

    cursor.execute("SELECT name,created,format,compress,ocr_text,latitude,longitude FROM assets WHERE id = ?", (photo_id,))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    name, created, format, compress, ocr_text, latitude, longitude = cursor.fetchone()
    # convert date_time to datetime object
    try:
        created = datetime.strptime(created, '%Y-%m-%d %H:%M:%S.%f')
    except:
        created = datetime.strptime(created, '%Y-%m-%d %H:%M:%S')

    if format.lower() in ['png', 'jpg', 'jpeg', 'avif', 'heic', 'ttif', 'webp']:
        path = f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.png'
        img = Image.open(path)
        width, height = img.size
        img.close()
    else:
        path = f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.mp4'
        vid = VideoFileClip(path)
        width, height = vid.size
        fps = vid.fps
        vid.close()

    size = os.path.getsize(path)

    if size > 1000000:
        size = str(round(size/1000000, 2))+" MB"
    else:
        size = str(round(size/1000))+" KB"

    cursor.execute("SELECT asset_faces.face_id, faces.name FROM asset_faces INNER JOIN faces ON asset_faces.face_id = faces.id WHERE asset_faces.asset_id = ?", (photo_id,))
    faces = cursor.fetchall()
    all_face = []
    for face in faces:
        all_face.append([face[0],'Unknown' if len(face[1]) == 32 else face[1]])
    
    return jsonify({
        "name":name, 
        "tags":tags,
        "date":created.strftime("%d-%m-%Y"), 
        "time": created.strftime("%I:%M %p"), 
        "format":format, 
        "compress":compress!=0, 
        "mp":str(round(width*height/1000000))+" MP", 
        "width":str(width), 
        "height":str(height), 
        "size":size,
        "faces":all_face,
        "location": {"latitude": latitude, "longitude": longitude} if latitude is not None and longitude is not None else None,
        "ocr_text":ocr_text
        })

# change date of assets     
@app.route('/api/redate', methods=['POST'])
def redate():
    # Logic to get the photo/video from the database or storage
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    try:
        date = request.form['date']  # format: YYYY-MM-DD
        # time = request.form['time']  # format: HH:MM
        time = None
        print(request.form['id'])
        photo_ids = request.form['id'].split(',')
    except Exception as e:
        print(e)
        return jsonify('Bad request'), 400
    print(username)
    open_dbs(username)

    new_master_folder_path = f'{config["path"]}/{username}/master/{str(int(date.split("-")[0]))}/{str(int(date.split("-")[1]))}/{str(int(date.split("-")[2]))}'
    new_preview_folder_path = f'{config["path"]}/{username}/preview/{str(int(date.split("-")[0]))}/{str(int(date.split("-")[1]))}/{str(int(date.split("-")[2]))}'
    if not os.path.exists(new_master_folder_path):
        os.makedirs(new_master_folder_path)
    if not os.path.exists(new_preview_folder_path):
        os.makedirs(new_preview_folder_path)

    for photo_id in photo_ids:
        old_date = cursor.execute("SELECT created FROM assets WHERE id = ?", (photo_id,)).fetchone()[0]
        try:
            old_date = datetime.strptime(old_date, '%Y-%m-%d %H:%M:%S.%f')
        except:
            old_date = datetime.strptime(old_date, '%Y-%m-%d %H:%M:%S')
        if time is None:
            new_date = datetime.strptime(date + " " + old_date.strftime('%H:%M'), '%Y-%m-%d %H:%M')
        else:
            new_date = datetime.strptime(date + " " + time, '%Y-%m-%d %H:%M')
        cursor.execute("UPDATE assets SET created = ? WHERE id = ?", (new_date, photo_id,))
        conn.commit()

        # move the photo/video to the new folder
        print(f'{config["path"]}/{username}/master/{old_date.year}/{old_date.month}/{old_date.day}/{photo_id}.png')
        try:
            # photo
            # check if image exists
            os.rename(f'{config["path"]}/{username}/master/{old_date.year}/{old_date.month}/{old_date.day}/{photo_id}.png', f'{new_master_folder_path}/{photo_id}.png')
            os.rename(f'{config["path"]}/{username}/preview/{old_date.year}/{old_date.month}/{old_date.day}/{photo_id}.webp', f'{new_preview_folder_path}/{photo_id}.webp')
        except:
            # video
            os.rename(f'{config["path"]}/{username}/master/{old_date.year}/{old_date.month}/{old_date.day}/{photo_id}.mp4', f'{new_master_folder_path}/{photo_id}.mp4')
            os.rename(f'{config["path"]}/{username}/preview/{old_date.year}/{old_date.month}/{old_date.day}/{photo_id}.gif', f'{new_preview_folder_path}/{photo_id}.gif')

        # delete the old folder if empty
        try:
            os.rmdir(f'{config["path"]}/{username}/master/{old_date.year}/{old_date.month}/{old_date.day}')
        except:
            pass

    cache.clear()
    return jsonify('Date changed successfully')

# change location of assets
@app.route('/api/location', methods=['POST'])
def change_location():
    # Logic to change the location of the assets
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    try:
        asset_ids = request.form['asset_id'].split(',')
    except:
        return jsonify('asset_ids not found'),404

    try:
        latitude = float(request.form['latitude'])
        longitude = float(request.form['longitude'])
    except KeyError:
        return jsonify('latitude/longitude not found'),404
    except ValueError:
        return jsonify('Invalid coordinates'),400

    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)
    for asset_id in asset_ids:
        cursor.execute("UPDATE assets SET latitude = ?, longitude = ? WHERE id = ?", (latitude, longitude, asset_id))
    conn.commit()
    cache.clear()
    return jsonify('Location changed successfully')


# deleted assets API
@app.route('/api/list/deleted', methods=['POST'])
@cache.cached(key_prefix=make_cache_key)
def get_deleted_list():
    # Logic to get the list of photos/videos from the database or storage
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    
    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)

    cursor.execute("SELECT DATE(deleted), GROUP_CONCAT(id), GROUP_CONCAT(IFNULL(duration, '')) FROM assets WHERE deleted != 0 GROUP BY DATE(deleted) ORDER BY deleted ASC")
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    
    result = cursor.fetchall()
    print(result)
    formatted_result = []
    current_date = datetime.now().date()
    for r in result[::-1]:
        date = r[0]
        if date == None:
            continue
        date = datetime.strptime(date, '%Y-%m-%d').date()
        # formatted_result.append([str(abs((current_date-date).days)), [[int(id)] for id in r[1].split(',')]])
        ids = []
        row1 = r[1].split(',')
        row2 = r[2].split(',')
        for i in range(len(row1)):
            if row2[i] != "":
                id_int = [int(row1[i]),None,row2[i]]
            else:
                id_int = [int(row1[i])]
            ids.append(id_int)
        formatted_result.append([str(abs((current_date-date).days)), ids])
    
    return jsonify(formatted_result)

# like/unkine assets
@app.route('/api/like/<string:username>/<int:asset_id>', methods=['POST'])
def like_unlike(username, asset_id):
    if username not in users:
        return jsonify('User not found'), 404
    open_dbs(username)
    cursor.execute("SELECT liked FROM assets WHERE id = ?", (asset_id,))

    if cursor.fetchone()[0] == None:
        cursor.execute("UPDATE assets SET liked = 1 WHERE id = ?", (asset_id,))
    else:
        cursor.execute("UPDATE assets SET liked = NULL WHERE id = ?", (asset_id,))
    conn.commit()
    cache.clear()
    return jsonify('Success')

# is asset liked
@app.route('/api/liked/<string:username>/<int:asset_id>', methods=['GET'])
@cache.cached()
def get_liked(username, asset_id):
    if username not in users:
        return jsonify('User not found'), 404
    open_dbs(username)
    cursor.execute("SELECT liked FROM assets WHERE id = ?", (asset_id,))
    return jsonify(cursor.fetchone()[0] != None)

# list of duplicate assets
@app.route('/api/list/duplicate', methods=['POST'])
@cache.cached(key_prefix=make_cache_key)
def get_duplicates():
    # Logic to get the list of photos/videos from the database or storage
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    
    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)

    cursor.execute("SELECT d.asset_id, d.asset_id2, DATE(a.created) FROM duplicates d JOIN assets a ON d.asset_id = a.id WHERE a.deleted = 0 and (select deleted from assets where id = d.asset_id2) = 0")


    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404

    result = cursor.fetchall()
    formatted_result = []
    for r in result:
        asset_id, asset_id2, created = r
        formatted_result.append([created, asset_id, asset_id2])

    return jsonify(formatted_result)

# count of current processing pending assets
@app.route('/api/pending/<string:username>', methods=['GET'])
@cache.cached(timeout=10)
def get_pending_count(username):
    # Logic to get the count of pending assets from the database or storage

    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)

    cursor.execute("SELECT COUNT(*) FROM assets WHERE blurry IS NULL")
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    result = cursor.fetchone()[0]

    # return format {"pending": count}
    return jsonify({"pending": result})



# --------------- CURD FACES APIS ---------------

# get a list of faces
@app.route('/api/list/faces', methods=['POST'])
@cache.cached(key_prefix=make_cache_key)
def get_list_faces():
    # Logic to get the list of faces from the database or storage
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify("username not found"),404
    print(username)
    open_dbs(username)

    while True:
        try:
            cursor.execute("SELECT faces.id, faces.name FROM faces JOIN asset_faces ON faces.id = asset_faces.face_id GROUP BY faces.id, faces.name ORDER BY COUNT(asset_faces.asset_id) DESC")
            result = cursor.fetchall()
            break
        except Exception as e:
            if 'recursive' in str(e):
                time.sleep(0.2)
                continue
            else:
                return jsonify('Face not found'), 404
    formatted_result = [[row[0], row[1] if len(row[1]) < 32 else "Unknown"] for row in result]
    return jsonify(formatted_result)

# get a list of photos/videos grouped by date for a particular face
@app.route('/api/list/face/<string:username>/<int:face_id>', methods=['GET'])
@cache.cached()
def get_grouped_list_face(username, face_id):
    # Logic to get the list of photos/videos from the database or storage for a particular face

    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)

    cursor.execute("SELECT DATE(assets.created), GROUP_CONCAT(DISTINCT assets.id), GROUP_CONCAT(IFNULL(duration, '')) FROM assets INNER JOIN asset_faces ON assets.id = asset_faces.asset_id WHERE assets.deleted = 0 AND asset_faces.face_id = ? GROUP BY DATE(assets.created)", (face_id,))
    # check if the photo exists
    result = None
    while result == None:
        try:
            if cursor.rowcount == 0:
                return jsonify('Photo not found'), 404
            result = cursor.fetchall()
        except:
            time.sleep(0.2)
            continue

    print(result)
    formatted_result = []
    for row in result[::-1]:
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
        # formatted_result.append([row[0], [[int(id)] for id in row[1].split(',')]])
    return jsonify(formatted_result)

# Get a name of faces
@app.route('/api/face/name/<string:username>/<int:face_id>', methods=['GET'])
@cache.cached()
def get_faces(username,face_id):
    # Logic to get the list of faces from the database or storage
    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)
    name = None
    cnt = None
    while name == None or cnt == None:
        try:
            cursor.execute("SELECT name FROM faces WHERE id = ?", (face_id,))
            name = cursor.fetchone()[0]
            # get count of photos in which the face is present
            cursor.execute("SELECT COUNT(*) FROM asset_faces WHERE face_id = ?", (face_id,))
            cnt = cursor.fetchone()[0]
        except:
            time.sleep(0.2)
            continue
        
    if len(name) == 32:
        name = 'Unknown'

    if cursor.rowcount == 0:
        return jsonify('Face not found'), 404

    return jsonify([name, cnt])

# Get a image of face
@app.route('/api/face/image/<string:username>/<int:face_id>', methods=['GET'])
def get_faces_image(username, face_id):
    # Logic to get the list of faces from the database or storage
    # Assuming the face images are stored in a directory named 'faces'
    if username not in users:
        return jsonify('User not found'), 404

    face_image_path = f'{config["path"]}/{username}/data/face/{face_id}.webp'
    
    # Check if the face image file exists
    if not os.path.exists(face_image_path):
        return jsonify('Face not found'), 404
    
    return send_file(face_image_path, mimetype='image/webp')

# Get a list of faces in a photo with coordinates
@app.route('/api/assetface/<int:asset>', methods=['GET'])
@cache.cached()
def get_assetface(asset):
    # Logic to get the list of faces from the database or storage

    username = ""
    try:
        username = request.args.get('username', '')
    except:pass
    print(username)
    open_dbs(username)

    cursor.execute("SELECT face_id,x,y,w,h FROM asset_faces WHERE asset_id = ?", (asset,))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    result = cursor.fetchall()
    formatted_result = [{"faceid":row[0], "x":row[1],"y":row[2],"w":row[3],"h":row[4]} for row in result]
    return jsonify(formatted_result)

# Join faces
@app.route('/api/face/join', methods=['POST'])
def join_faces():
    # Logic to join the faces
    username = ""
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found'), 404
    except:
        return jsonify('username not found'),404
    
    try:
        main_face_id1 = int(request.form['main_face_id1'])
        side_face_id2 = int(request.form['side_face_id2'])
    except:
        return jsonify('Bad request'), 400

    if main_face_id1 == side_face_id2:
        return jsonify('Faces are same'), 400

    open_dbs(username)

    cursor.execute("DELETE FROM faces WHERE id = ?", (side_face_id2,))

    os.remove(f'{config["path"]}/{username}/data/face/{side_face_id2}.webp')

    # move traing data from side_face_id2 to main_face_id1
    for i in os.listdir(f"{config['path']}/{username}/data/training/{side_face_id2}"):
        os.rename(f"{config['path']}/{username}/data/training/{side_face_id2}/{i}", f"{config['path']}/{username}/data/training/{main_face_id1}/{i}")
    os.rmdir(f"{config['path']}/{username}/data/training/{side_face_id2}")
    
    # Remove rows that would violate the unique constraint before performing the update.
    cursor.execute("""
        DELETE FROM asset_faces
        WHERE face_id = ?
          AND EXISTS (
              SELECT 1 FROM asset_faces af2
              WHERE af2.asset_id = asset_faces.asset_id
                AND af2.face_id = ?
          )
    """, (side_face_id2, main_face_id1))

    # join faces
    cursor.execute("UPDATE asset_faces SET face_id = ? WHERE face_id = ?", (main_face_id1, side_face_id2))

    # NOT needed as before face verification it auto-updates model

    # # Update the trained model after joining faces
    # t = threading.Thread(target=background_funs.trainModel, args=(f"{config['path']}/{username}/data/training",), daemon=True)
    # t.start()
    # t.join()


    conn.commit()
    cache.clear()
    return jsonify("Faces joined successfully")

# add face to a photo
@app.route('/api/face/add', methods=['POST'])
def add_face():
    # Logic to add a face to a photo
    username = ""
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found'), 404
    except:
        return jsonify('username not found'),404
    
    try:
        asset_id = request.form['asset_id']
        face_id = request.form['face_id']
    except:
        return jsonify('Bad request'), 400

    open_dbs(username)

    # Check if face already exists for this asset
    cursor.execute("SELECT 1 FROM asset_faces WHERE asset_id=? AND face_id=?", (int(asset_id), int(face_id)))
    if cursor.fetchone():
        return jsonify("Face added successfully")

    cursor.execute("INSERT INTO asset_faces (asset_id,face_id) VALUES (?,?)", (int(asset_id), int(face_id),))
    conn.commit()
    cache.clear()
    return jsonify("Face added successfully")

# remove face from a photo
@app.route('/api/face/remove', methods=['POST'])
def remove_face():
    # Logic to remove a face from a photo
    username = ""
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found'), 404
    except:
        return jsonify('username not found'),404
    
    try:
        asset_id = request.form['asset_id'].split(',')
        face_id = request.form['face_id']
    except:
        return jsonify('Bad request'), 400

    open_dbs(username)

    for i in asset_id:
        cursor.execute("DELETE FROM asset_faces WHERE asset_id = ? AND face_id = ?", (int(i), int(face_id),))
    conn.commit()
    cache.clear()
    return jsonify("Face removed successfully")

# Replace faces
@app.route('/api/face/replace/<int:new_face_id>/<int:asset_id>/<int:x>/<int:y>/<int:w>/<int:h>/', methods=['POST'])
def replace_faces(new_face_id, asset_id, x, y, w, h):
    
    username = ""
    try:
        username = request.form['username']
    except:pass
    open_dbs(username)

    cursor.execute("UPDATE asset_faces SET face_id = ? WHERE asset_id = ? AND x = ? AND y = ? AND w = ? AND h = ?", (new_face_id, asset_id, x, y, w, h))
    if cursor.rowcount == 0:
        return jsonify('Face not found'), 404
    conn.commit()
    cache.clear()
    return jsonify("Faces replaced successfully")

# Rename faces
@app.route('/api/face/rename/<string:username>/<int:face_id>/<string:name>', methods=['GET'])
def rename_face(username, face_id, name):
    
    if username not in users:
        return jsonify('User not found'), 404
    
    open_dbs(username)

    cursor.execute("UPDATE faces SET name = ? WHERE id = ?", (name, face_id))
    if cursor.rowcount == 0:
        return jsonify('Face not found'), 404
    conn.commit()
    cache.clear()
    return jsonify("Face renamed successfully")

# No faces
@app.route('/api/face/noname', methods=['POST'])
def no_name_faces():
    # Logic to remove names from faces
    username = ""
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found'), 404
    except:
        return jsonify('username not found'),404
    try:
        ids = request.form['name'].split(',')
    except:
        return jsonify('Bad request'), 400
    
    print(username)
    open_dbs(username)

    for i in ids:
        cursor.execute("UPDATE faces SET name = ? WHERE id = ?", (uuid.uuid4().hex, int(i)))
    conn.commit()

    cache.clear()
    return jsonify("Faces renamed successfully")

# delete a face
@app.route('/api/face/delete/<string:username>/<int:face_id>', methods=['DELETE'])
def delete_face(username, face_id):

    # Logic to delete a face    
    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)
    face_path = f'{config["path"]}/{username}/data/face/{face_id}.webp'
    training_dir = f'{config["path"]}/{username}/data/training/{face_id}'

    if os.path.exists(face_path):
        os.remove(face_path)

    if os.path.isdir(training_dir):
        shutil.rmtree(training_dir, ignore_errors=True)

    # delete the face from the database
    cursor.execute("DELETE FROM asset_faces WHERE face_id = ?", (face_id,))
    cursor.execute("DELETE FROM faces WHERE id = ?", (face_id,))
    conn.commit()
    cache.clear()
    return jsonify("Face deleted successfully")


# -------------------- VERIFICATION APIS --------------------

# Get pending verifications
@app.route('/api/face/verify/pending/<string:username>', methods=['GET'])
@cache.cached()
def get_pending_verifications(username):
    if username not in users:
        return jsonify('User not found'), 404
    
    open_dbs(username)
    
    # Fetch faces with verified = 0 (Predicted)
    query = """
        SELECT af.asset_id, af.face_id, f.name, af.x, af.y, af.w, af.h, a.created
        FROM asset_faces af
        JOIN faces f ON af.face_id = f.id
        JOIN assets a ON af.asset_id = a.id
        WHERE af.verified = 0
        LIMIT 50
    """
    cursor.execute(query)
    rows = cursor.fetchall()
    
    result = []
    for row in rows:
        result.append({
            "asset_id": row[0],
            "face_id": row[1],
            "person_name": row[2],
            "box": {"x": row[3], "y": row[4], "w": row[5], "h": row[6]},
            "created": row[7]
        })
        
    return jsonify(result)

# Update verification status
@app.route('/api/face/verify/update', methods=['POST'])
def update_face_verification():
    username = request.form.get('username')
    asset_id = request.form.get('asset_id')
    face_id = request.form.get('face_id')
    status = request.form.get('status') # 'true' (verified) or 'false' (rejected)
    
    if not username or not asset_id or not face_id or status is None:
        return jsonify("Missing parameters"), 400
        
    open_dbs(username)
    
    is_verified = str(status).lower() == 'true'
    
    if is_verified:
        # 1. Update DB to verified = 1
        cursor.execute("UPDATE asset_faces SET verified = 1 WHERE asset_id = ? AND face_id = ?", (asset_id, face_id))
        conn.commit()
        
        # 2. Add to training data
        cursor.execute("SELECT x, y, w, h FROM asset_faces WHERE asset_id = ? AND face_id = ?", (asset_id, face_id))
        coords = cursor.fetchone()
        
        if coords:
            x, y, w, h = coords
            cursor.execute("SELECT created, format FROM assets WHERE id = ?", (asset_id,))
            res = cursor.fetchone()
            if res:
                created, fmt = res
                try:
                    if isinstance(created, str):
                        if '.' in created:
                            dt = datetime.strptime(created, '%Y-%m-%d %H:%M:%S.%f')
                        else:
                            dt = datetime.strptime(created, '%Y-%m-%d %H:%M:%S')
                    else:
                        dt = created
                except:
                    dt = datetime.now()
                
                # Construct path to master image
                image_path = f'{config["path"]}/{username}/master/{dt.year}/{dt.month}/{dt.day}/{asset_id}.png'
                
                if os.path.exists(image_path):
                    img = cv2.imread(image_path)
                    if img is not None:
                        # Apply padding logic
                        w_pad = round(w * 0.4)
                        h_pad = round(h * 0.4)
                        height, width, _ = img.shape
                        
                        x1 = max(x - w_pad, 0)
                        y1 = max(y - h_pad, 0)
                        x2 = min(x + w + w_pad, width)
                        y2 = min(y + h + h_pad, height)
                        
                        cropped = img[y1:y2, x1:x2]
                        
                        # Save to training
                        # Use a unique name: asset_id + face_id + x
                        train_path = f"{config['path']}/{username}/data/training/{face_id}/{asset_id}_{face_id}_{x}.jpg"
                        os.makedirs(os.path.dirname(train_path), exist_ok=True)
                        cv2.imwrite(train_path, cropped)
                        
                        # Trigger retraining in background
                        threading.Thread(target=background_funs.trainModel, args=(f"{config['path']}/{username}/data/training",)).start()
        cache.clear()
        return jsonify("Verified")
    else:
        # Update verified = -1 (Rejected)
        cursor.execute("UPDATE asset_faces SET verified = -1 WHERE asset_id = ? AND face_id = ?", (asset_id, face_id))
        conn.commit()
        cache.clear()
        return jsonify("Rejected")








# -------------------- NORMAL ALBUMS --------------------

# get a list of albums
@app.route('/api/list/albums', methods=['POST'])
@cache.cached(key_prefix=make_cache_key)
def get_list_albums():
    # Logic to get the list of albums from the database or storage

    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    open_dbs(username)

    cursor.execute("SELECT id,name,cover,start FROM album")
    result = cursor.fetchall()
    if result is None:
        return jsonify([])
    formatted_result = [[str(row[0]) or "", row[1] or "", row[2] or "", row[3] or ""] for row in result]
    return jsonify(formatted_result)
    
    # [id, trip name, cover image id, start date]

# Create an album
@app.route('/api/album/create', methods=['POST'])
def create_album():
    # Logic to create an album
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    open_dbs(username)

    name = request.form['name']
    # start = request.form['start']
    # end = request.form['end']
    # location = request.form['location']

    cursor.execute("INSERT INTO album (name) VALUES (?)", (name,))
    conn.commit()
    cache.clear()
    return jsonify("Album created successfully")

# add photos/videos to an album
@app.route('/api/album/add', methods=['POST'])
def add_to_album():
    # Logic to add photos/videos to an album
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    open_dbs(username)

    try:
        album_id = request.form['album_id']
        asset_ids = request.form['asset_id'].split(',')
    except:
        return jsonify('Bad request'), 400  

    try:
        cursor.execute("SELECT cover FROM album WHERE id = ?", (album_id,))
        cover = cursor.fetchone()[0]
    except:
        cover = None

    for asset_id in asset_ids:
        if cover == None:
            cursor.execute("UPDATE album SET cover = ? WHERE id = ?", (asset_id, album_id))
            cover = asset_id
        try:
            cursor.execute("INSERT INTO album_assets (album_id,asset_id) VALUES (?,?)", (album_id, asset_id))
        except:
            pass
    conn.commit()
    cache.clear()
    return jsonify("Photos added to album successfully")

# remove photos/videos from an album
@app.route('/api/album/remove', methods=['POST'])
def remove_from_album():
    # Logic to remove photos/videos from an album
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    open_dbs(username)

    album_id = request.form['album_id']
    asset_ids = request.form['asset_ids'].split(',')

    for asset_id in asset_ids:
        cursor.execute("DELETE FROM album_assets WHERE album_id = ? AND asset_id = ?", (album_id, asset_id))
    conn.commit()
    cache.clear()
    return jsonify("Photos removed from album successfully")

# delete an album
@app.route('/api/album/delete', methods=['POST'])
def delete_album():
    # Logic to delete an album
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    try:
        album_id = request.form['album_id']
    except:
        return jsonify('Bad request'), 400
    open_dbs(username)

    cursor.execute("DELETE FROM album WHERE id = ?", (album_id,))
    cursor.execute("DELETE FROM album_assets WHERE album_id = ?", (album_id,))
    conn.commit()
    cache.clear()
    return jsonify("Album deleted successfully")

# get a list of photos/videos in an album
@app.route('/api/album/<string:username>/<int:album_id>', methods=['GET'])
@cache.cached()
def get_album(username, album_id):
    # Logic to get the list of photos/videos from the database or storage for a particular album
    if username not in users:
        return jsonify('User not found'), 404
    
    open_dbs(username)
    cursor.execute("SELECT DATE(assets.created), GROUP_CONCAT(assets.id), GROUP_CONCAT(IFNULL(duration, '')) FROM album_assets INNER JOIN assets ON album_assets.asset_id = assets.id WHERE album_assets.album_id = ? AND assets.deleted = 0 GROUP BY DATE(assets.created) ORDER BY assets.created DESC", (album_id,))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    
    formatted_result = []
    result = cursor.fetchall()
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
        # formatted_result.append([row[0], [[int(id)] for id in row[1].split(',')]])
    return jsonify(formatted_result)

    # print(result)
    # formatted_result = {row[0]: [int(id) for id in row[1].split(',')] for row in result}
    # return jsonify(formatted_result)

# rename an album
@app.route('/api/album/rename', methods=['POST'])
def rename_album():
    # Logic to rename an album
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    try:
        album_id = request.form['album_id']
        name = request.form['name']
    except:
        return jsonify('Bad request'), 400

    open_dbs(username)

    cursor.execute("UPDATE album SET name = ? WHERE id = ?", (name, album_id))
    conn.commit()
    return jsonify("Album renamed successfully")

# redate an album
@app.route('/api/album/redate', methods=['POST'])
def redate_album():
    # Logic to redate an album
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    try:
        album_id = request.form['album_id']
        date = request.form['date']  # format: YYYY-MM-DD
    except:
        return jsonify('Bad request'), 400

    open_dbs(username)

    cursor.execute("UPDATE album SET start = ? WHERE id = ?", (date, album_id))
    conn.commit()
    return jsonify("Album redated successfully")




# -------------------- AUTO ALBUMS --------------------

# Get a list of auto albums
@app.route('/api/list/autoalbums', methods=['POST'])
@cache.cached(key_prefix=make_cache_key)
def get_list_autoalbums():
    # Logic to get the list of auto albums from the database or storage

    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404
    print(username)
    open_dbs(username)

    docums = []

    book = [513,514,515,518,519,2808,2954,3030]
    id = [2201,2202, 649,739]
    note = [268, 2807, 2808, 2809, 2810]
    recipemenu = [3327, 2623]
    text = [2462, 4129, 1362]
    screenshot = [3562]

    for docs in [[book, "Books"], [id, "ID Cards"], [note, "Note"], [recipemenu, "Recipe & Menu"], [text, "Text"], [screenshot, "Screenshots"]]:
        cursor.execute("""
            SELECT assets.id, DATE(assets.created)
            FROM asset_tags
            JOIN tags ON asset_tags.tag_id = tags.id
            JOIN assets ON asset_tags.asset_id = assets.id AND assets.deleted = 0
            WHERE asset_tags.tag_id IN ({})
            LIMIT 1;
        """.format(','.join('?' for _ in docs[0])), docs[0])
        c = cursor.fetchone()
        if c != None:
            docums.append([docs[1],str(c[0]), c[1]])

    Places = []

    swimming = [4032, 4033, 4034, 4035, 4036, 329]
    nightclub = [2802, 2803]
    food = [213, 783, 1589, 1590, 1368, 1730, 1731, 1732, 1733, 1734, 1735, 3578, 3940, 4462]
    animals = [78, 79, 80]
    train = [622, 2957, 3883, 4236, 4237, 4238, 4239, 4240, 4241]
    sunset = [3996, 3997, 3998, 3999, 4000, 1536]
    wedding = [574, 2395, 4445, 4446, 4447, 4448, 4449, 4450, 4451, 4452, 4453, 4454, 4455]
    park = [2939, 2940, 2941, 2942, 2943, 2944, 3701, 4421, 71, 195, 733, 941, 1831, 1836]
    airplane = [40, 2068, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 2069]
    sky = [3722, 3723, 3724, 3725, 3726, 484, 1535, 2800]
    waterfall = [4431]
    cars = [727, 729, 730, 183, 184, 185, 186, 187, 188, 189, 190, 191, 642, 643, 644, 645, 646, 188, 670, 674, 1486, 1572, 2667, 3150, 3282, 4002]
    temple = [156, 4111, 2696, 2900, 2094]
    birthday = [679, 446, 447, 448, 449, 450, 1227]
    forests = [1757, 192, 193, 194, 195, 196, 3300, 1968, 2295, 2550, 4540, 1758, 1759, 1760, 1761, 3059, 251]
    farms = [1577, 1578, 1579, 1580, 1225, 1196, 29, 2042, 1836, 2136, 4256, 4499]
    snow = [3755, 3756, 3757, 3758, 3759, 3760, 3761, 3762, 3763, 3764, 3765, 3766, 471, 3716, 3709, 3710, 3711, 3712, 3713, 3714, 3715, 3717, 3718]
    mountain = [2713, 2714, 2715, 2716, 2717, 2718, 2719, 2720, 2721, 2722, 2723, 2724, 2725, 2726, 2727, 2728, 2729, 2090, 2091, 2092, 2093, 967, 1605]
    hike = [2086, 2087, 2088, 2089, 966]


    for place_name in [[swimming, "Swimming"], [nightclub, "Nightclub"], [food, "Food"], [animals, "Animals"], [train, "Train"], [sunset, "Sunset"], [wedding, "Wedding"], [park, "Park"], [airplane, "Airplane"], [sky, "Sky"], [waterfall, "Waterfall"], [cars, "Cars"], [temple, "Temple"], [birthday, "Birthday"], [forests, "Forests"], [farms, "Farms"], [snow, "Snow"], [mountain, "Mountain"], [hike, "Hike"]]:
        cursor.execute("""
            SELECT assets.id, DATE(assets.created)
            FROM asset_tags
            JOIN tags ON asset_tags.tag_id = tags.id
            JOIN assets ON asset_tags.asset_id = assets.id AND assets.deleted = 0
            WHERE asset_tags.tag_id IN ({})
            LIMIT 1;
        """.format(','.join('?' for _ in place_name[0])), place_name[0])
        c = cursor.fetchone()
        # print(c)
        if c != None:
            Places.append([place_name[1],str(c[0]),c[1]])
        



    cursor.execute("""
SELECT t.tag, COUNT(*) AS count, a.id, DATE(a.created)
FROM asset_tags AS at
JOIN tags AS t ON at.tag_id = t.id
JOIN assets AS a ON at.asset_id = a.id AND a.deleted = 0
GROUP BY at.tag_id
ORDER BY count DESC 
LIMIT 25;
""")
    Things = []
    c = cursor.fetchall()
    # print(c)
    for row in c:
        if len(Things) >= 10:break
        if not is_verb(row[0]):
            Things.append([row[0].capitalize(), str(row[2]), row[3]])
    # print(Things)

    return jsonify({"Places":Places, "Things":Things, "Documents":docums})



    cursor.execute("SELECT id,name FROM auto_albums")
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Auto albums not found'), 404
    result = cursor.fetchall()
    formatted_result = {row[0]: row[1] for row in result}
    return jsonify(formatted_result)

def is_verb(word):
    synsets = wn.synsets(word)
    for synset in synsets:
        if synset.pos() == 'v':  # 'v' denotes verb
            return True
    return False

# get images of auto albums
@app.route('/api/autoalbum/<string:username>/<string:auto_album_name>', methods=['GET'])
def get_autoalbum(username, auto_album_name:str):
    # Logic to get the list of photos/videos from the database or storage for a particular auto album
    if username not in users:
        return jsonify('User not found'), 404
    open_dbs(username)
    

    tags = []
    if auto_album_name == "Books":
        tags = [513,514,515,518,519,2808,2954,3030]
    elif auto_album_name == "ID Cards":
        tags = [2201,2202, 649,739]
    elif auto_album_name == "Note":
        tags = [268, 2807, 2808, 2809, 2810]
    elif auto_album_name == "Recipe & Menu":
        tags = [3327, 2623]
    elif auto_album_name == "Text":
        tags = [2462, 4129, 1362]
    elif auto_album_name == "Screenshots":
        tags = [3562]
    elif auto_album_name == "Swimming":
        tags = [4032, 4033, 4034, 4035, 4036, 329]
    elif auto_album_name == "Nightclub":
        tags = [2802, 2803]
    elif auto_album_name == "Food":
        tags = [213, 783, 1589, 1590, 1368, 1730, 1731, 1732, 1733, 1734, 1735, 3578, 3940, 4462]
    elif auto_album_name == "Animals":
        tags = [78, 79, 80]
    elif auto_album_name == "Train":
        tags = [622, 2957, 3883, 4236, 4237, 4238, 4239, 4240, 4241]
    elif auto_album_name == "Sunset":
        tags = [3996, 3997, 3998, 3999, 4000, 1536]
    elif auto_album_name == "Wedding":
        tags = [574, 2395, 4445, 4446, 4447, 4448, 4449, 4450, 4451, 4452, 4453, 4454, 4455]
    elif auto_album_name == "Park":
        tags = [2939, 2940, 2941, 2942, 2943, 2944, 3701, 4421, 71, 195, 733, 941, 1831, 1836]
    elif auto_album_name == "Airplane":
        tags = [40, 2068, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 2069]
    elif auto_album_name == "Sky":
        tags = [3722, 3723, 3724, 3725, 3726, 484, 1535, 2800]
    elif auto_album_name == "Waterfall":
        tags = [4431]
    # elif auto_album_name == "Fog":
    #     tags = [1718, 1719, 3747, 3880, 2691]
    elif auto_album_name == "Cars":
        tags = [727, 729, 730, 183, 184, 185, 186, 187, 188, 189, 190, 191, 642, 643, 644, 645, 646, 188, 670, 674, 1486, 1572, 2667, 3150, 3282, 4002]
    elif auto_album_name == "Temple":
        tags = [156, 4111, 2696, 2900, 2094]
    elif auto_album_name == "Birthday":
        tags = [679, 446, 447, 448, 449, 450, 1227]
    elif auto_album_name == "Forests":
        tags = [1757, 192, 193, 194, 195, 196, 3300, 1968, 2295, 2550, 4540, 1758, 1759, 1760, 1761, 3059, 251]
    elif auto_album_name == "Farms":
        tags = [1577, 1578, 1579, 1580, 1225, 1196, 29, 2042, 1836, 2136, 4256, 4499]
    elif auto_album_name == "Snow":
        tags = [3755, 3756, 3757, 3758, 3759, 3760, 3761, 3762, 3763, 3764, 3765, 3766, 471, 3716, 3709, 3710, 3711, 3712, 3713, 3714, 3715, 3717, 3718]
    elif auto_album_name == "Mountain":
        tags = [2713, 2714, 2715, 2716, 2717, 2718, 2719, 2720, 2721, 2722, 2723, 2724, 2725, 2726, 2727, 2728, 2729, 2090, 2091, 2092, 2093, 967, 1605]
    elif auto_album_name == "Hike":
        tags = [2086, 2087, 2088, 2089, 966]  

    else:
        # get tagid of the auto_album_name
        while 1:
            try:
                cursor.execute("SELECT id FROM tags WHERE tag = ?", (auto_album_name.lower(),))
                tags = [row[0] for row in cursor.fetchall()]
                break
            except Exception as e:
                if "recursive" in str(e):
                    time.sleep(random.randint(1, 3) / 10)
                    continue
                else:
                    print(e)
                    return jsonify('Auto album not found'), 404

    while 1:
        try:
            cursor.execute("SELECT asset_tags.asset_id, assets.created,  FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE tag_id IN ({}) AND assets.deleted = 0 ORDER BY assets.created DESC".format(','.join('?' for _ in tags)), tags)
            break
        except Exception as e:
            if "recursive" in str(e):
                time.sleep(0.2)
                continue
            else:
                print(e)
                return jsonify('Auto album not found'), 404

    # check if the photo exists
    result = cursor.fetchall()
    if result == None or len(result) == 0:
        return jsonify('Photo not found'), 404
    id, created = random.choice(result)
    try:
        date_time = datetime.strptime(created, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(created, '%Y-%m-%d %H:%M:%S')
    
    return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(id)+'.webp', mimetype=f'image/webp')
    
    return send_file(fr'E:\Picfolio\meet244\preview\2021\12\21\130.webp', mimetype=f'image/webp')





# --------------- SEARCH APIS ---------------

def tag2id(tag):
    cursor.execute("SELECT id FROM tags WHERE tag = ?", (tag,))
    return cursor.fetchone()[0]

def id2tag(id):
    cursor.execute("SELECT tag FROM tags WHERE id = ?", (id,))
    return cursor.fetchone()[0]

# Search assets 
@app.route('/api/search', methods=['POST'])
def search():
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found'), 404
    except:
        return jsonify('username not found'),404
    try:
        query = request.form['query']
    except:
        return jsonify('query not found'),404
    try:
        qtype = request.form['type']
    except:
        qtype = "search"

    print(username, query, qtype)

    open_dbs(username)
    query = query.lower().strip()
    # Logic to search the assets

    if query == "screenshot" or query == "screenshots":
        try:
            cursor.execute("SELECT DATE(assets.created), GROUP_CONCAT(assets.id) AS asset_id FROM asset_tags AS at JOIN assets ON at.asset_id = assets.id WHERE at.tag_id = 3562 AND assets.deleted = 0 GROUP BY DATE(assets.created)")
            result = cursor.fetchall()
            formatted_result =[]
            for row in result[::-1]:
                formatted_result.append([row[0], [[int(id)] for id in row[1].split(',')]])
            return jsonify(formatted_result)
        except Exception as e:
            print(e)
            return jsonify({})

    if qtype == "buttons":
        if query == "":
            return jsonify({})
        elif query == "favourite":
            try:
                cursor.execute("SELECT DATE(created), GROUP_CONCAT(id) FROM assets WHERE liked = 1 AND deleted = 0 GROUP BY DATE(created)")
                result = cursor.fetchall()
                print(result)
                formatted_result =[]
                for row in result[::-1]:
                    formatted_result.append([row[0], [[int(id)] for id in row[1].split(',')]])
                return jsonify(formatted_result)
            except Exception as e:
                print(e)
                return jsonify({})   
        elif query == "blurry":
            try:
                cursor.execute("SELECT DATE(created), GROUP_CONCAT(id) FROM assets WHERE blurry = 1 AND deleted = 0 GROUP BY DATE(created)")
                result = cursor.fetchall()
                formatted_result =[]
                for row in result[::-1]:
                    formatted_result.append([row[0], [[int(id)] for id in row[1].split(',')]])
                return jsonify(formatted_result)
            except Exception as e:
                print(e)
                return jsonify({})

    #Auto Albums
    elif qtype == "auto albums":
        
        tags = []

        if query == "text":
            tags = [2462, 4129, 1362]
        elif query == "recipe & menu":
            tags = [3327, 2623]
        elif query == "note":
            tags = [268, 2807, 2808, 2809, 2810]
        elif query == "id cards":
            tags = [2201,2202, 649,739]
        elif query == "books":
            tags = [513,514,515,518,519,2808,2954,3030]
        elif query == "swimming":
            tags = [4032, 4033, 4034, 4035, 4036, 329]
        elif query == "nightclub":
            tags = [2802, 2803]
        elif query == "food":
            tags = [213, 783, 1589, 1590, 1368, 1730, 1731, 1732, 1733, 1734, 1735, 3578, 3940, 4462]
        elif query == "animals":
            tags = [78, 79, 80]
        elif query == "train":
            tags = [622, 2957, 3883, 4236, 4237, 4238, 4239, 4240, 4241]
        elif query == "sunset":
            tags = [3996, 3997, 3998, 3999, 4000, 1536]
        elif query == "wedding":
            tags = [574, 2395, 4445, 4446, 4447, 4448, 4449, 4450, 4451, 4452, 4453, 4454, 4455]
        elif query == "park":
            tags = [2939, 2940, 2941, 2942, 2943, 2944, 3701, 4421, 71, 195, 733, 941, 1831, 1836]
        elif query == "airplane":
            tags = [40, 2068, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 2069]
        elif query == "sky":
            tags = [3722, 3723, 3724, 3725, 3726, 484, 1535, 2800]
        elif query == "waterfall":
            tags = [4431]
        # elif query == "fog":
        #     tags = [1718, 1719, 3747, 3880, 2691]
        elif query == "cars":
            tags = [727, 729, 730, 183, 184, 185, 186, 187, 188, 189, 190, 191, 642, 643, 644, 645, 646, 188, 670, 674, 1486, 1572, 2667, 3150, 3282, 4002]
        elif query == "temple":
            tags = [156, 4111, 2696, 2900, 2094]
        elif query == "birthday":
            tags = [679, 446, 447, 448, 449, 450, 1227]
        elif query == "forests":
            tags = [1757, 192, 193, 194, 195, 196, 3300, 1968, 2295, 2550, 4540, 1758, 1759, 1760, 1761, 3059, 251]
        elif query == "farms":
            tags = [1577, 1578, 1579, 1580, 1225, 1196, 29, 2042, 1836, 2136, 4256, 4499]
        elif query == "snow":
            tags = [3755, 3756, 3757, 3758, 3759, 3760, 3761, 3762, 3763, 3764, 3765, 3766, 471, 3716, 3709, 3710, 3711, 3712, 3713, 3714, 3715, 3717, 3718]
        elif query == "mountain":
            tags = [2713, 2714, 2715, 2716, 2717, 2718, 2719, 2720, 2721, 2722, 2723, 2724, 2725, 2726, 2727, 2728, 2729, 2090, 2091, 2092, 2093, 967, 1605]
        elif query == "hike":
            tags = [2086, 2087, 2088, 2089, 966]        
        else:
            try:
                tagids = []
                for tag in query.split(" "):
                    tagids.append(tag2id(tag))
                print(tagids)
                cursor.execute("SELECT GROUP_CONCAT(asset_tags.asset_id), DATE(assets.created) FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE tag_id IN ({}) AND assets.deleted = 0 GROUP BY DATE(assets.created)".format(','.join('?' for _ in tagids)), tagids)
                result = cursor.fetchall()
                print(result)
                formatted_result = []
                for row in result:
                    formatted_result.append([row[1], [[int(id)] for id in row[0].split(',')]])

                return jsonify(formatted_result)
            except:
                return jsonify({})

        if tags != []:
            try:
                cursor.execute("SELECT DATE(assets.created), GROUP_CONCAT(asset_tags.asset_id) FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE tag_id IN ({}) AND assets.deleted = 0 GROUP BY DATE(assets.created)".format(','.join('?' for _ in tags)), tags)
                result = cursor.fetchall()
                formatted_result = []
                print(result)   
                for row in result:
                    formatted_result.append([row[0], [[int(id)] for id in row[1].split(',')]])
                return jsonify(formatted_result)
            except:
                return jsonify({})

    # Albums
    elif qtype == "albums":
        # query is album id
        cursor.execute("SELECT DATE(assets.created), assets.id FROM album_assets JOIN assets ON album_assets.asset_id = assets.id WHERE album_assets.album_id = ? AND (assets.deleted = 0 OR assets.deleted IS NULL) ORDER BY assets.created", (query,))
        result = cursor.fetchall()
        grouped_result = {}
        # do if required
        return jsonify(grouped_result)
    
    isOnly = False
    if 'only' in query:
        query = query.replace('only', '').strip()
        isOnly = True
    
    print("usernames", username)
    print("query", query)

    # perform local search  - if gemini api is not available

    faces = []
    tags = []
    ocr_assets = []

    # check in config
    if not config.get("gemini_api_key") or config.get("gemini_api_key") == "":
        # local search
        print("local search")
        # local search logic here

        # match faces (locally)
        try:
            # Fetch all name variations from DB
            cursor.execute("SELECT id, name FROM faces")
            rows = cursor.fetchall()

            # Create lookup dictionary: {'mum': 2, 'meet': 1, ...}
            # Filter out 32-char UUIDs which are likely 'Unknown' faces
            alias_map = {row[1].lower(): row[0] for row in rows if len(row[1]) != 32}

            if alias_map:
                tokens = query.split()
                found_ids = set()
                matched_words = []
                known_names = list(alias_map.keys())

                for word in tokens:
                    # Fuzzy match each word against known names
                    match = process.extractOne(word, known_names, scorer=fuzz.ratio, score_cutoff=85)

                    if match:
                        matched_alias = match[0]
                        person_id = alias_map[matched_alias]
                        found_ids.add(person_id)
                        matched_words.append(word)

                # Update faces list with found IDs
                faces = list(found_ids)
                print("Matched face IDs:", faces)

                # Remove identified names from the query string for further tag search
                remaining_tokens = [t for t in tokens if t not in matched_words]
                query = " ".join(remaining_tokens)
        except Exception as e:
            print(f"Error in local face matching: {e}")

        # match tags (locally)
        try:
            with open('backend/tag_vector_space.pkl', 'rb') as f:
                vector_data = pickle.load(f)
            
            known_tags = vector_data['tags']
            tag_embeddings = vector_data['embeddings']
            
            # Initialize model
            st_model = SentenceTransformer('all-MiniLM-L6-v2')

            found_tags = set()
            
            # A. Exact Match
            for tag in known_tags:
                if re.search(r'\b' + re.escape(tag.lower()) + r'\b', query):
                    found_tags.add(tag)

            # B. Semantic Search
            query_embedding = st_model.encode(query, convert_to_tensor=True)

            if isinstance(tag_embeddings, torch.Tensor):
                tag_embeddings = tag_embeddings.to(query_embedding.device)
            else:
                tag_embeddings = torch.tensor(tag_embeddings).to(query_embedding.device)

            cos_scores = util.cos_sim(query_embedding, tag_embeddings)[0]
            
            # Get top 5 matches with > 80% similarity
            top_results = sorted(enumerate(cos_scores), key=lambda x: x[1], reverse=True)[:5]
            for idx, score in top_results:
                if score > 0.75:  # similarity threshold
                    found_tags.add(known_tags[idx])
            
            tags = list(found_tags)
            print("Matched tags:", tags)
        except Exception as e:
            print(f"Error in local tag matching: {e}")
    
        # match OCR text (locally)
        try:
            if query.strip():
                # Use FTS5 MATCH operator for fast full-text search
                # We wrap the query in double quotes to treat it as a phrase search if needed, 
                # or just pass it directly. For simple words, passing directly is fine.
                # To be safe against syntax errors, we can use the standard binding.
                cursor.execute("""
                    SELECT f.image_id 
                    FROM images_ocr_fts f
                    JOIN assets a ON f.image_id = a.id
                    WHERE f.ocr_text LIKE ? AND a.deleted = 0
                """, (f"%{query}%",))
                ocr_assets = [row[0] for row in cursor.fetchall()]

                print("Matched OCR assets:", len(ocr_assets))
        except Exception as e:
            print(f"Error in local OCR matching: {e}")

    else:
        print("gemini search")
        # TODO: gemini search

    
    # sql search query filtering with tags and faces
    # it must have atleast 1 tag-matched and all faces(if any)
    if not faces and not tags and not ocr_assets:
        return jsonify([])

    result = []

    # Collect all candidate asset IDs
    tag_asset_ids = set()
    if tags:
        placeholders = ','.join('?' for _ in tags)
        cursor.execute(f"SELECT id FROM tags WHERE tag IN ({placeholders})", tags)
        tag_ids = [row[0] for row in cursor.fetchall()]
        
        if tag_ids:
            t_ids_placeholders = ','.join('?' for _ in tag_ids)
            cursor.execute(f"SELECT DISTINCT asset_id FROM asset_tags WHERE tag_id IN ({t_ids_placeholders})", tag_ids)
            tag_asset_ids = set(row[0] for row in cursor.fetchall())

    ocr_asset_ids = set(ocr_assets)
    
    # Union of Tags and OCR (Parallel Branch)
    candidate_ids = tag_asset_ids | ocr_asset_ids

    # Face Filtering (Sequential Branch)
    face_asset_ids = set()
    if faces:
        placeholders = ','.join('?' for _ in faces)
        subquery = f"""
            SELECT asset_id 
            FROM asset_faces 
            WHERE face_id IN ({placeholders}) 
            GROUP BY asset_id 
            HAVING COUNT(DISTINCT face_id) = ?
        """
        cursor.execute(subquery, faces + [len(faces)])
        face_asset_ids = set(row[0] for row in cursor.fetchall())

    # Combine Results
    final_ids = set()
    if faces:
        if candidate_ids:
            # Faces AND (Tags OR OCR)
            final_ids = face_asset_ids & candidate_ids
        else:
            # Only Faces (if query was fully consumed by faces)
            final_ids = face_asset_ids
    else:
        # No Faces -> Just Tags OR OCR
        final_ids = candidate_ids

    if not final_ids:
        return jsonify([])

    # Fetch details for final IDs
    placeholders = ','.join('?' for _ in final_ids)
    final_query = f"""
        SELECT DATE(created), GROUP_CONCAT(id), GROUP_CONCAT(IFNULL(duration, ''))
        FROM assets
        WHERE id IN ({placeholders}) AND deleted = 0
        GROUP BY DATE(created)
        ORDER BY created DESC
    """
    cursor.execute(final_query, list(final_ids))
    result = cursor.fetchall()

    formatted_result = []
    for row in result:
        ids = []
        row1 = row[1].split(',')
        row2 = row[2].split(',')
        for i in range(len(row1)):
            if row2[i] != "":
                id_int = [int(row1[i]), None, row2[i]]
            else:
                id_int = [int(row1[i])]
            ids.append(id_int)
        formatted_result.append([row[0], ids])
    
    return jsonify(formatted_result)



# --------------- Stats APIs ---------------

@app.route('/api/stats', methods=['POST'])
def stats():
    try:
        username = request.form['username']
        if username not in users:
            return jsonify('User not found'), 404
    except:
        return jsonify('username not found'),404

    open_dbs(username)
    # Logic to get the stats
    cursor.execute("SELECT format, COUNT(*) AS count FROM assets GROUP BY format")
    asset_counts = cursor.fetchall()
    image_counts = {}
    video_counts = {}

    for format, count in asset_counts:
        if format in ['png', 'jpg', 'jpeg', 'avif', 'heic', 'ttif', 'webp', 'jfif']:
            image_counts[format] = count
        elif format in ['mp4', 'mov', 'avi', 'webm', 'flv', 'wmv', 'mkv']:
            video_counts[format] = count

    cursor.execute("SELECT strftime('%Y', created) AS year, COUNT(*) AS count FROM assets GROUP BY year;")
    yearly_counts = cursor.fetchall()

    cursor.execute('''SELECT album.name, COUNT(album_assets.asset_id) AS img_count
                FROM album
                INNER JOIN album_assets ON album.id = album_assets.album_id
                GROUP BY album.id
                ORDER BY img_count DESC
                LIMIT 3''')
    top_albums = cursor.fetchall()

    cursor.execute("""
        SELECT latitude, longitude, COUNT(*) AS img_count
        FROM assets
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL
        GROUP BY latitude, longitude
        ORDER BY img_count DESC
        LIMIT 3;
        """)
    location_rows = cursor.fetchall()
    top_locations = [
        {"latitude": row[0], "longitude": row[1], "count": row[2]}
        for row in location_rows
    ]

    # storage available on the server 
    # total storage available on the server
    total_storage = shutil.disk_usage(config['path'])
    used_storage = total_storage.used / 1024 / 1024 / 1024
    total_storage = total_storage.total / 1024 / 1024 / 1024
    used_storage = round(used_storage, 2)
    total_storage = round(total_storage, 2)

    return jsonify({
        "image_counts": image_counts,
        "video_counts": video_counts,
        "yearly_counts": yearly_counts,
        "top_albums": top_albums,
        "top_locations": top_locations,
        "used_storage": used_storage,
        "total_storage": total_storage
    })




def start_this():
    # while True: #todo: remove this
    run_background_script()
    print("Server started")
    serve(app, host="0.0.0.0", port=7251, threads=1)
    # app.run(host="0.0.0.0", port=7251, debug=False) # multiple bg threads here
    # app.run(port=7251, debug=False) # multiple bg threads here

def run_background_script():
    global background_process
    try:
        background_process = subprocess.Popen([sys.executable, 'backend/background.py'])
        # Don't wait - let it run in the background
    except Exception as e:
        print(f"Background script error: {e}")

def stop_background_script():
    global background_process
    if background_process is not None:
        try:
            # Terminate the process
            if os.name == 'nt':  # Windows
                background_process.terminate()
                # Give it a moment to terminate gracefully
                try:
                    background_process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    # Force kill if it doesn't terminate
                    background_process.kill()
            else:  # Unix-like
                background_process.terminate()
                try:
                    background_process.wait(timeout=2)
                except subprocess.TimeoutExpired:
                    background_process.kill()
            print("Background script stopped")
        except Exception as e:
            print(f"Error stopping background script: {e}")
        finally:
            background_process = None

if __name__ == '__main__':    # remove if karan is running
    start_this()

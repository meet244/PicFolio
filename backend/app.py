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
from moviepy.editor import VideoFileClip
import gemini
import nltk
from nltk.corpus import wordnet as wn

nltk.download('wordnet')
load_dotenv()

# LOAD GEMINI API
genai.configure(api_key=os.getenv('Gemini'))
model = genai.GenerativeModel('gemini-pro')

tags = None
with open("ram_tag_list.txt", "r") as file:
    tags = file.read()

config = None

def read_config():
    global config
    if os.path.exists('config.json'):
        with open('config.json') as f:
            config = json.load(f)
    else:
        config = {"users": ["family"], "path": ""}
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
        os.system(f'python dbmake.py {username}')
    conn = sqlite3.connect(f'{config["path"]}/{username}/data.db', check_same_thread=False)
    cursor = conn.cursor()

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
@app.route('/api/user/create/<string:username>', methods=['POST'])
def create_user(username):
    # Logic to create user
    if username in users:
        return jsonify({'error': 'User already exists'}), 400
    else:
        users.append(username)
        config['users'] = users
        save_config()
        os.system(f'python dbmake.py {username}')
        read_config()
        return jsonify({'message': 'User created successfully'})

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
                elif tag == 'GPSInfo':  # TODO: get location from GPSInfo
                    pass
            
            img.close()

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
@app.route('/api/restore/<string:username>/<string:ids>', methods=['POST'])
def restore_photo(username, ids):
    # Logic to restore the photo from the database or storage
    if username not in users:
        return jsonify('User not found'), 404
    try:
        ids = ids.split(',')
    except:
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
    try:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

    try:
        return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.webp', mimetype=f'image/webp')
    except:
        try:
            return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.gif', mimetype=f'image/gif')
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
    print(username)
    open_dbs(username)

    cursor.execute("SELECT DATE(created), GROUP_CONCAT(id) FROM assets WHERE deleted = 0 GROUP BY DATE(created)")
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    result = cursor.fetchall()
    formatted_result = {row[0]: [int(id) for id in row[1].split(',')] for row in result}
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

# get asset details
@app.route('/api/details/<string:username>/<int:photo_id>', methods=['GET'])
def get_details(username, photo_id):
    # Logic to get the photo/video from the database or storage

    if username not in users:
        return jsonify('User not found'), 404
    
    open_dbs(username)

    cursor.execute("SELECT tags.tag FROM asset_tags INNER JOIN tags ON asset_tags.tag_id = tags.id WHERE asset_tags.asset_id = ?", (photo_id,))
    tags = [tag[0] for tag in cursor.fetchall()]

    cursor.execute("SELECT name,created,format,compress FROM assets WHERE id = ?", (photo_id,))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    name, created, format, compress = cursor.fetchone()
    # convert date_time to datetime object
    try:
        created = datetime.strptime(created, '%Y-%m-%d %H:%M:%S.%f')
    except:
        created = datetime.strptime(created, '%Y-%m-%d %H:%M:%S')

    if format.lower() in ['png', 'jpg', 'jpeg', 'avif', 'heic', 'ttif', 'webp']:
        img = Image.open(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.png')
        width, height = img.size
        img.close()

        size = os.path.getsize(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.png')

        if size > 1000000:
            size = str(round(size/1000000, 2))+" MB"
        else:
            size = str(round(size/1000))+" KB"

        cursor.execute("SELECT asset_faces.face_id, faces.name FROM asset_faces INNER JOIN faces ON asset_faces.face_id = faces.id WHERE asset_faces.asset_id = ?", (photo_id,))
        faces = cursor.fetchall()
        faces = {str(face[0]): 'Unknown' if len(face[1]) == 32 else face[1] for face in faces}
        
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
            "faces":faces,
            "location":None
            })
    else:
        size = os.path.getsize(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.png')

        if size > 1000000:
            size = str(round(size/1000000, 2))+" MB"
        else:
            size = str(round(size/1000))+" KB"

        cursor.execute("SELECT asset_faces.face_id, faces.name FROM asset_faces INNER JOIN faces ON asset_faces.face_id = faces.id WHERE asset_faces.asset_id = ?", (photo_id,))
        faces = cursor.fetchall()
        print(faces)
        faces = [face[0] for face in faces]

        vid = VideoFileClip(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.mp4')
        width, height = vid.size
        fps = vid.fps
        vid.close()
        
        return jsonify({"name":name, 
        "tags":tags,
        "date": created.strftime("%d-%m-%Y"), 
        "time": created.strftime("%I:%M %p"), 
        "format":format, 
        "compress":compress!=0, 
        "fps":fps, 
        "width":width, 
        "height":height, 
        "size":size,
        "faces":faces,
        "location":None})

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

    return jsonify('Date changed successfully')

# deleted assets API
@app.route('/api/list/deleted', methods=['POST'])
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

    cursor.execute("SELECT id, deleted FROM assets WHERE deleted != 0 ORDER BY deleted DESC")
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    
    result = cursor.fetchall()
    formatted_result = {}
    current_date = datetime.now().date()
    for r in result:
        asset_id, deleted_date = r
        deleted_date = datetime.strptime(str(deleted_date), '%Y-%m-%d %H:%M:%S.%f').date()
        difference = (deleted_date - current_date).days
        if difference not in formatted_result:
            formatted_result[difference] = []
        formatted_result[difference].append(asset_id)
    
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
    return jsonify('Success')

@app.route('/api/liked/<string:username>/<int:asset_id>', methods=['GET'])
def get_liked(username, asset_id):
    if username not in users:
        return jsonify('User not found'), 404
    open_dbs(username)
    cursor.execute("SELECT liked FROM assets WHERE id = ?", (asset_id,))
    return jsonify(cursor.fetchone()[0] != None)

@app.route('/api/list/duplicate', methods=['POST'])
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
    
# --------------- CURD FACES APIS ---------------

# get a list of faces
@app.route('/api/list/faces', methods=['POST'])
def get_list_faces():
    # Logic to get the list of faces from the database or storage
    username = ""
    try:
        username = request.form['username']
    except:pass 
    print(username)
    open_dbs(username)

    cursor.execute("SELECT id,name FROM faces")
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Face not found'), 404
    result = cursor.fetchall()
    formatted_result = {row[0]: row[1] if len(row[1]) < 32 else "Unknown" for row in result}
    return jsonify(formatted_result)

# get a list of photos/videos grouped by date for a particular face
@app.route('/api/list/face/<string:username>/<int:face_id>', methods=['GET'])
def get_grouped_list_face(username, face_id):
    # Logic to get the list of photos/videos from the database or storage for a particular face

    if username not in users:
        return jsonify('User not found'), 404

    open_dbs(username)

    cursor.execute("SELECT DATE(assets.created), GROUP_CONCAT(DISTINCT assets.id) FROM assets INNER JOIN asset_faces ON assets.id = asset_faces.asset_id WHERE assets.deleted = 0 AND asset_faces.face_id = ? GROUP BY DATE(assets.created)", (face_id,))
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
    formatted_result = {row[0]: list(set([int(id) for id in row[1].split(',')])) for row in result}
    return jsonify(formatted_result)

# Get a name of faces
@app.route('/api/face/name/<string:username>/<int:face_id>', methods=['GET'])
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
def get_assetface(asset):
    # Logic to get the list of faces from the database or storage

    username = ""
    try:
        username = request.form['username']
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
    
    cursor.execute("UPDATE asset_faces SET face_id = ? WHERE face_id = ?", (main_face_id1, side_face_id2))

    # threading.Thread(target=background_funs.trainModel, args=(f"{config['path']}/{username}/data/training",), daemon=True).start()

    conn.commit()
    return jsonify("Faces joined successfully")

# Delete faces
# @app.route('/api/face/delete/<int:face_id>', methods=['DELETE'])
# def delete_faces(face_id):
#     # Logic to delete the face
#     username = ""
#     try:
#         username = request.form['username']
#     except:pass
#     open_dbs(username)

#     cursor.execute("DELETE FROM faces WHERE id = ?", (face_id,))

#     if cursor.rowcount == 0:
#         return jsonify('Face not found'), 404

#     os.remove(f'{config["path"]}/{username}/data/face/{face_id}.webp')

#     # delete traing data dir

#     for i in os.listdir(f"{config['path']}/{username}/data/training/{face_id}"):
#         os.remove(f"{config['path']}/{username}/data/training/{face_id}/{i}")
#     os.rmdir(f"{config['path']}/{username}/data/training/{face_id}")
    
#     cursor.execute("DELETE FROM asset_faces WHERE face_id = ?", (face_id,))

#     # threading.Thread(target=background_funs.trainModel, args=(f"{config['path']}/{username}/data/training",), daemon=True).start()

#     conn.commit()
#     return jsonify("Faces deleted successfully")

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
    return jsonify("Face renamed successfully")

# No of faces
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

    return jsonify("Faces renamed successfully")




# -------------------- NORMAL ALBUMS --------------------

# get a list of albums
@app.route('/api/list/albums', methods=['POST'])
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
    return jsonify("Album deleted successfully")

# get a list of photos/videos in an album
@app.route('/api/album/<string:username>/<int:album_id>', methods=['GET'])
def get_album(username, album_id):
    # Logic to get the list of photos/videos from the database or storage for a particular album
    if username not in users:
        return jsonify('User not found'), 404
    
    open_dbs(username)
    cursor.execute("SELECT DATE(assets.created), GROUP_CONCAT(assets.id) FROM album_assets INNER JOIN assets ON album_assets.asset_id = assets.id WHERE album_assets.album_id = ? AND assets.deleted = 0 GROUP BY DATE(assets.created)", (album_id,))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    result = cursor.fetchall()
    print(result)
    formatted_result = {row[0]: [int(id) for id in row[1].split(',')] for row in result}
    return jsonify(formatted_result)

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






# -------------------- AUTO ALBUMS --------------------

# Get a list of auto albums
@app.route('/api/list/autoalbums', methods=['POST'])
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
        cursor.execute("SELECT * FROM asset_tags WHERE tag_id IN ({}) LIMIT 1".format(','.join('?' for _ in docs[0])), docs[0])
        if cursor.fetchone() != None:
            docums.append(docs[1])

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
    # fog = [1718, 1719, 3747, 3880, 2691]
    cars = [727, 729, 730, 183, 184, 185, 186, 187, 188, 189, 190, 191, 642, 643, 644, 645, 646, 188, 670, 674, 1486, 1572, 2667, 3150, 3282, 4002]
    temple = [156, 4111, 2696, 2900, 2094]
    birthday = [679, 446, 447, 448, 449, 450, 1227]
    forests = [1757, 192, 193, 194, 195, 196, 3300, 1968, 2295, 2550, 4540, 1758, 1759, 1760, 1761, 3059, 251]
    farms = [1577, 1578, 1579, 1580, 1225, 1196, 29, 2042, 1836, 2136, 4256, 4499]
    snow = [3755, 3756, 3757, 3758, 3759, 3760, 3761, 3762, 3763, 3764, 3765, 3766, 471, 3716, 3709, 3710, 3711, 3712, 3713, 3714, 3715, 3717, 3718]
    mountain = [2713, 2714, 2715, 2716, 2717, 2718, 2719, 2720, 2721, 2722, 2723, 2724, 2725, 2726, 2727, 2728, 2729, 2090, 2091, 2092, 2093, 967, 1605]
    hike = [2086, 2087, 2088, 2089, 966]


    for place_name in [[swimming, "Swimming"], [nightclub, "Nightclub"], [food, "Food"], [animals, "Animals"], [train, "Train"], [sunset, "Sunset"], [wedding, "Wedding"], [park, "Park"], [airplane, "Airplane"], [sky, "Sky"], [waterfall, "Waterfall"], [cars, "Cars"], [temple, "Temple"], [birthday, "Birthday"], [forests, "Forests"], [farms, "Farms"], [snow, "Snow"], [mountain, "Mountain"], [hike, "Hike"]]:
        cursor.execute("SELECT * FROM asset_tags WHERE tag_id IN ({}) LIMIT 1".format(','.join('?' for _ in place_name[0])), place_name[0])
        if cursor.fetchone() != None:
            Places.append(place_name[1])
        



    cursor.execute("""
SELECT t.tag, COUNT(*) AS count
FROM asset_tags AS at
JOIN tags AS t ON at.tag_id = t.id
JOIN assets AS a ON at.asset_id = a.id AND a.deleted = 0
GROUP BY at.tag_id
ORDER BY count DESC 
LIMIT 25;
""")
    Things = []
    for row in cursor.fetchall():
        if len(Things) >= 10:break
        if not is_verb(row[0]):
            Things.append(row[0].capitalize())
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
            cursor.execute("SELECT asset_tags.asset_id, assets.created FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE tag_id IN ({}) AND assets.deleted = 0 ORDER BY assets.created DESC".format(','.join('?' for _ in tags)), tags)
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


# --------------- FAMILY MOVE IN / OUT ---------------

# Move personal assets to family
@app.route('/api/family/move/<int:asset_id>', methods=['POST'])
def move_to_family(asset_id):
    # get date and format of image
    username = ""
    try:
        username = request.form['username']
    except:pass
    open_dbs(username)

    cursor.execute('''SELECT name, created, format FROM assets WHERE id = ?''', (asset_id,))
    result = cursor.fetchone()
    name = result[0]
    date_time = result[1]
    image_format = result[2]
    # convert date_time to datetime object
    date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    # move image to family/temp folder
    os.rename(f'{config["path"]}/{username}/master/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.{image_format}', f'{config["path"]}/family/temp/{asset_id}.{image_format}')
    # update database
    cursor.execute("DELETE FROM assets WHERE id = ?", (asset_id,))
    conn.commit()

    # insert into family database
    open_dbs("family")
    cursor.execute("INSERT INTO assets (name, format, created) VALUES (?, ?, ?)", (name, image_format, date_time))
    conn.commit()
    cursor.execute("SELECT MAX(id) FROM assets")
    id = cursor.fetchone()[0]

    # save the image to family/master and family/preview
    os.rename(f'{config["path"]}/{username}/master/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.{image_format}', f'{config["path"]}/family/master/{date_time.year}/{date_time.month}/{date_time.day}/{id}.{image_format}')
    try:
        os.rename(f'{config["path"]}/{username}/preview/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.webp', f'family/preview/{date_time.year}/{date_time.month}/{date_time.day}/{id}.webp')
    except:
        os.rename(f'{config["path"]}/{username}/preview/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.gif', f'family/preview/{date_time.year}/{date_time.month}/{date_time.day}/{id}.gif')
        
    return jsonify("Image moved to family successfully")

# Move family assets to personal
@app.route('/api/family/moveback/<int:asset_id>', methods=['POST'])
def moveback_to_personal(asset_id):
    # get date and format of image
    username = ""
    try:
        username = request.form['username']
    except:pass
    open_dbs("family")

    cursor.execute('''SELECT name, created, format FROM assets WHERE id = ?''', (asset_id,))
    result = cursor.fetchone()
    name = result[0]
    date_time = result[1]
    image_format = result[2]
    # convert date_time to datetime object
    date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    # move image to family/temp folder
    os.rename(f'{config["path"]}/family/master/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.{image_format}', f'{username}/temp/{asset_id}.{image_format}')
    # update database
    cursor.execute("DELETE FROM assets WHERE id = ?", (asset_id,))
    conn.commit()

    # insert into user database
    open_dbs(username)
    cursor.execute("INSERT INTO assets (name, format, created) VALUES (?, ?, ?)", (name, image_format, date_time))
    conn.commit()
    cursor.execute("SELECT MAX(id) FROM assets")
    id = cursor.fetchone()[0]

    # save the image to user/master and user/preview
    os.rename(f'{config["path"]}/family/master/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.{image_format}', f'{username}/master/{date_time.year}/{date_time.month}/{date_time.day}/{id}.{image_format}')
    try:
        os.rename(f'{config["path"]}/family/preview/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.webp', f'{username}/preview/{date_time.year}/{date_time.month}/{date_time.day}/{id}.webp')
    except:
        os.rename(f'{config["path"]}/family/preview/{date_time.year}/{date_time.month}/{date_time.day}/{asset_id}.gif', f'{username}/preview/{date_time.year}/{date_time.month}/{date_time.day}/{id}.gif')
        
    return jsonify(f"Image moved to {username} successfully")



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

    open_dbs(username)
    query = query.lower().strip()
    # Logic to search the assets

    if query == "screenshot" or query == "screenshots":
        try:
            cursor.execute("SELECT assets.id AS asset_id, assets.created FROM asset_tags AS at JOIN assets ON at.asset_id = assets.id WHERE at.tag_id = 3562 AND assets.deleted = 0")
            result = cursor.fetchall()
            grouped_result = {}
            for row in result:
                created_date = row[1].split()[0]
                asset_id = row[0]
                if created_date in grouped_result:
                    grouped_result[created_date].append(asset_id)
                else:
                    grouped_result[created_date] = [asset_id]
            return jsonify(grouped_result)
        except:
            return jsonify({})

    if qtype == "buttons":
        if query == "":
            return jsonify({})
        elif query == "favourite":
            try:
                cursor.execute("SELECT created, id FROM assets WHERE liked = 1 AND deleted = 0")
                result = cursor.fetchall()
                grouped_result = {}
                for row in result:
                    created_date = row[0].split()[0]
                    asset_id = row[1]
                    if created_date in grouped_result:
                        grouped_result[created_date].append(asset_id)
                    else:
                        grouped_result[created_date] = [asset_id]
                return jsonify(grouped_result)
            except:
                return jsonify({})   
        elif query == "blurry":
            try:
                cursor.execute("SELECT id, created, blurry FROM assets WHERE blurry IS 1 AND deleted = 0")
                result = cursor.fetchall()
                grouped_result = {}
                for row in result:
                    created_date = row[1].split()[0]
                    asset_id = row[0]
                    if created_date in grouped_result:
                        grouped_result[created_date].append(asset_id)
                    else:
                        grouped_result[created_date] = [asset_id]
                return jsonify(grouped_result)
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
        elif len(query.split(" ")) <= 2:
            try:
                tagids = []
                for tag in query.split(" "):
                    tagids.append(tag2id(tag))
                print(tagids)
                cursor.execute("SELECT asset_tags.asset_id, assets.created FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE tag_id IN ({}) AND assets.deleted = 0 ORDER BY assets.created ASC".format(','.join('?' for _ in tagids)), tagids)
                result = cursor.fetchall()
                print(result)
                if len(result) != 0 and result != None:
                    grouped_result = {}
                    for row in result:
                        created_date = row[1].split()[0]
                        asset_id = row[0]
                        if created_date in grouped_result:
                            grouped_result[created_date].append(asset_id)
                        else:
                            grouped_result[created_date] = [asset_id]
                    return jsonify(grouped_result)
            except:
                return jsonify({})
        
        if tags != []:
            try:
                cursor.execute("SELECT asset_tags.asset_id, assets.created FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE tag_id IN ({}) AND assets.deleted = 0 ORDER BY assets.created ASC".format(','.join('?' for _ in tags)), tags)
                result = cursor.fetchall()
                grouped_result = {}
                for row in result:
                    created_date = row[1].split()[0]
                    asset_id = row[0]
                    if created_date in grouped_result:
                        grouped_result[created_date].append(asset_id)
                    else:
                        grouped_result[created_date] = [asset_id]
                return jsonify(grouped_result)
            except:
                return jsonify({})

    # Albums
    elif qtype == "albums":
        # query is album id
        cursor.execute("SELECT DATE(assets.created), assets.id FROM album_assets JOIN assets ON album_assets.asset_id = assets.id WHERE album_assets.album_id = ? AND (assets.deleted = 0 OR assets.deleted IS NULL) ORDER BY assets.created", (query,))
        result = cursor.fetchall()
        grouped_result = {}
        for row in result:
            created_date = row[0]
            asset_id = row[1]
            if created_date in grouped_result:
                grouped_result[created_date].append(asset_id)
            else:
                grouped_result[created_date] = [asset_id]
        return jsonify(grouped_result)
    
    isOnly = False
    if 'only' in query:
        query = query.replace('only', '').strip()
        isOnly = True
    
    print("usernames", username)
    print("query", query)

    print("AI search")
    faces = []
    tags = []
    r = gemini.get_ai_names(query)
    if r !=None:
        faces = r
    
    if len(query.replace('and','').split(" ")) > 3+len(faces) or len(faces) == 0:
        r = gemini.get_ai_tags(query)
        if r !=None:
            tags = r
    
    print(faces, tags)

    if len(faces) == 0 and len(tags) == 0:
        print("nothing")
        return jsonify({})
    if len(faces) == 0:
        print("search with tags")
        # cursor.execute("SELECT DISTINCT asset_tags.asset_id, assets.created FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE asset_tags.tag_id IN ({})".format(','.join('?' for _ in tags)), [])
        # Get tag_ids from the tags list
        tag_ids = cursor.execute("SELECT id FROM tags WHERE tag IN ({})".format(','.join('?' for _ in tags)), tags).fetchall()
        tag_ids = [tag[0] for tag in tag_ids]

        # Retrieve asset_ids and created dates based on the tag_ids
        cursor.execute("SELECT DISTINCT asset_id, created FROM asset_tags JOIN assets ON asset_tags.asset_id = assets.id WHERE asset_tags.tag_id IN ({})".format(','.join('?' for _ in tag_ids)), tag_ids)
    elif len(tags) == 0:
        print("search with faces")
        cursor.execute("SELECT DISTINCT assets.id, assets.created FROM asset_faces JOIN assets ON asset_faces.asset_id = assets.id WHERE asset_faces.face_id IN (SELECT id FROM faces WHERE LOWER(name) IN ({}) ) GROUP BY assets.id, assets.created HAVING COUNT(DISTINCT asset_faces.face_id) = {}".format(','.join(['?']*len(faces)), len(faces)), [f.lower() for f in faces])
    else:
        # print("search with both tag and face")
        # cursor.execute("SELECT DISTINCT assets.id, assets.created FROM asset_faces JOIN assets ON asset_faces.asset_id = assets.id WHERE asset_faces.face_id IN (SELECT id FROM faces WHERE name IN {}) AND assets.id IN (SELECT asset_id FROM asset_tags WHERE tag_id IN ({})) GROUP BY assets.id, assets.created".format(tuple(faces), ','.join('?' for _ in tags)), tags)
        print("search with both tag and face")
        # Get the IDs of the tags from the tags list
        tag_ids = cursor.execute("SELECT id FROM tags WHERE tag IN ({})".format(','.join('?' for _ in tags)), tags).fetchall()
        tag_ids = [tag[0] for tag in tag_ids]

        # Retrieve assets that have all the faces and are associated with at least one of the tags
        cursor.execute("SELECT DISTINCT af.asset_id, a.created FROM asset_faces af JOIN assets a ON af.asset_id = a.id WHERE af.face_id IN (SELECT id FROM faces WHERE name IN ({})) AND af.asset_id IN (SELECT asset_id FROM asset_tags WHERE tag_id IN ({})) GROUP BY af.asset_id, a.created HAVING COUNT(DISTINCT af.face_id) = {}".format(','.join(['?']*len(faces)), ','.join('?' for _ in tag_ids), len(faces)), [f.lower() for f in faces] + tag_ids)

    result = cursor.fetchall()
    print(result)
    grouped_result = {}
    for row in result:
        created_date = row[1].split()[0]
        asset_id = row[0]
        if created_date in grouped_result:
            grouped_result[created_date].append(asset_id)
        else:
            grouped_result[created_date] = [asset_id]
    return jsonify(grouped_result)


def AiAearch(query):

    resp = []

    def get_tags(sent):
        response = model.generate_content(tags+"\n\n\n From above tags, i want you to give me related and proper tags, each separated by comma related to following sentence - \n\n\n"+sent)  
        print("got")
        for i in response.text.split(','):
            resp.append(i.strip())


    threads = []
    t = threading.Thread(target=get_tags, args=(search,))
    threads.append(t)
    t.start()
    t = threading.Thread(target=get_tags, args=(search,))
    threads.append(t)
    t.start()
    t = threading.Thread(target=get_tags, args=(search,))
    threads.append(t)
    t.start()

    for t in threads:
        t.join()
    resp = set(resp)

    f = []
    for t in resp:
        for tg in tags.splitlines():
            if tg.lower() == t.lower():
                f.append(tg)

    tag_ids = [tag2id(tag) for tag in f]
    cursor.execute("SELECT asset_id FROM asset_tags WHERE tag_id IN ({})".format(','.join('?' for _ in tag_ids)), tag_ids)
    result = cursor.fetchall()
    result = [id[0] for id in result]
    return jsonify(list(set(result)))

def start_this():
    # while True: #todo: remove this
    # threading.Thread(target=run_background_script, daemon=True).start()
    print("Server started")
    # serve(app, host="0.0.0.0", port=7251)
    app.run(host="0.0.0.0", port=7251, debug=False) # multiple bg threads here

def run_background_script():
        os.system('python background.py')

if __name__ == '__main__':    # remove if karan is running
    start_this()

from flask import Flask, jsonify, request, send_file, render_template
# import flask_cors
import json
import sqlite3
import threading
import os
import uuid
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
# flask_cors.CORS(app)

# Error handler for 404 Not Found
@app.errorhandler(404)
def not_found_error(error):
    return jsonify({'error': 'Not Found'}), 404

# Error handler for 500 Internal Server Error
@app.errorhandler(500)
def internal_server_error(error):
    return jsonify({'error': 'Internal Server Error'}), 500

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
@app.route('/api/delete', methods=['DELETE'])
def delete_photo():
    # Logic to delete the photo from the database or storage (master and preview)
    username = ""
    try:
        username = request.form['username']
        ids = request.form['id'].split(',')
    except:
        return "Improper params"
    print(username)
    open_dbs(username)
    success= []
    fail = []
    for i in ids:
        delete_date = datetime.now() + timedelta(days=90)
        cursor.execute("UPDATE assets SET deleted = ? WHERE id = ?", (delete_date, i,))
        # check if the photo exists
        if cursor.rowcount != 0:success.append(i)
        else:fail.append(i)
    conn.commit()
    return jsonify({"success":success, "failed":fail})

# get a photo/video preview
@app.route('/api/preview/<string:username>/<int:photo_id>', methods=['GET'])
def preview_asset(username,photo_id):
    # Logic to get the preview photo/video from the database or storage
    # username = ""
    # try:
    #     username = request.form['username']
    # except:
    #     return jsonify('username not found'),404
    if username not in users:
        return jsonify('User not found'), 404
    # print(username)
    open_dbs(username)

    cursor.execute("SELECT created FROM assets WHERE id = ?", (photo_id,))

    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404

    # print(cursor.fetchone())
    date_time = cursor.fetchone()[0]

    # convert date_time to datetime object
    try:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
    except:
        date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

    try:
        return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.webp', mimetype=f'image/webp')
    except:
        return send_file(f'{config["path"]}/{username}/preview/'+str(date_time.year)+'/'+str(date_time.month)+'/'+str(date_time.day)+'/'+str(photo_id)+'.gif', mimetype=f'image/gif')
    
# get a photo/video original
@app.route('/api/asset/<string:username>/<int:photo_id>', methods=['GET'])
def get_asset(username,photo_id):
    # Logic to get the photo/video from the database or storage
    
    if username not in users:
        return jsonify('User not found'), 404

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

# get asset details
@app.route('/api/details/<int:photo_id>', methods=['GET'])
def get_details(photo_id):
    # Logic to get the photo/video from the database or storage
    username = ""
    try:
        username = request.form['username']
    except:pass
    print(username)
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

        cursor.execute("SELECT face_id FROM asset_faces WHERE asset_id = ?", (photo_id,))
        faces = cursor.fetchall()
        faces = [face[0] for face in faces]
        
        return jsonify({"name":name, 
        "tags":tags,
        "date":created.strftime("%d-%m-%Y"), 
        "time":created.strftime("%H:%M"), 
        "format":format, 
        "compress":compress!=0, 
        "mp":str(round(width*height/1000000))+" MP", 
        "width":str(width), 
        "height":str(height), 
        "size":size,
        "faces":faces,
        "location":None})
    else:
        size = os.path.getsize(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.png')

        if size > 1000000:
            size = str(round(size/1000000, 2))+" MB"
        else:
            size = str(round(size/1000))+" KB"

        cursor.execute("SELECT face_id FROM asset_faces WHERE asset_id = ?", (photo_id,))
        faces = cursor.fetchall()
        faces = [face[0] for face in faces]

        vid = VideoFileClip(f'{config["path"]}/{username}/master/'+str(created.year)+'/'+str(created.month)+'/'+str(created.day)+'/'+str(photo_id)+'.mp4')
        width, height = vid.size
        fps = vid.fps
        vid.close()
        
        return jsonify({"name":name, 
        "tags":tags,
        "date":created.strftime("%d-%m-%Y"), 
        "time":created.strftime("%H:%M"), 
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
        pass
    print(username)
    open_dbs(username)
    try:
        date = request.form['date']  # format: YYYY-MM-DD
        time = request.form['time']  # format: HH:MM
        photo_ids = request.form['id'].split(',')
    except:
        return jsonify('Bad request'), 400

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


# --------------- CURD FACES APIS ---------------

# get a list of faces
@app.route('/api/list/faces', methods=['GET'])
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
@app.route('/api/list/face/<int:face_id>', methods=['GET'])
def get_grouped_list_face(face_id):
    # Logic to get the list of photos/videos from the database or storage for a particular face
    username = ""
    try:
        username = request.form['username']
    except:
        return jsonify('username not found'),404 
    print(username)
    open_dbs(username)

    cursor.execute("SELECT DATE(assets.created), GROUP_CONCAT(assets.id) FROM assets INNER JOIN asset_faces ON assets.id = asset_faces.asset_id WHERE assets.deleted = 0 AND asset_faces.face_id = ? GROUP BY DATE(assets.created)", (face_id,))
    # check if the photo exists
    if cursor.rowcount == 0:
        return jsonify('Photo not found'), 404
    result = cursor.fetchall()
    formatted_result = {row[0]: [int(id) for id in row[1].split(',')] for row in result}
    return jsonify(formatted_result)

# Get a name of faces
@app.route('/api/face/name/<int:face_id>', methods=['GET'])
def get_faces(face_id):
    # Logic to get the list of faces from the database or storage

    username = ""
    try:
        username = request.form['username']
    except:pass
    print(username)
    open_dbs(username)

    cursor.execute("SELECT name FROM faces WHERE face_id = ?", (face_id,))
    name = cursor.fetchone()[0]

    if cursor.rowcount == 0:
        return jsonify('Face not found'), 404

    return jsonify(name)

# Get a image of faces
@app.route('/api/face/image/<int:face_id>', methods=['GET'])
def get_faces_image(face_id):
    # Logic to get the list of faces from the database or storage
    # Assuming the face images are stored in a directory named 'faces'
    username = ""
    try:
        username = request.form['username']
    except:pass
    print(username)
    open_dbs(username)

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
@app.route('/api/face/join/<int:main_face_id1>/<int:side_face_id2>', methods=['POST'])
def join_faces(main_face_id1, side_face_id2):
    # Logic to join the faces
    username = ""
    try:
        username = request.form['username']
    except:pass

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
@app.route('/api/face/delete/<int:face_id>', methods=['DELETE'])
def delete_faces(face_id):
    # Logic to delete the face
    username = ""
    try:
        username = request.form['username']
    except:pass
    open_dbs(username)

    cursor.execute("DELETE FROM faces WHERE id = ?", (face_id,))

    if cursor.rowcount == 0:
        return jsonify('Face not found'), 404

    os.remove(f'{config["path"]}/{username}/data/face/{face_id}.webp')

    # delete traing data dir

    for i in os.listdir(f"{config['path']}/{username}/data/training/{face_id}"):
        os.remove(f"{config['path']}/{username}/data/training/{face_id}/{i}")
    os.rmdir(f"{config['path']}/{username}/data/training/{face_id}")
    
    cursor.execute("DELETE FROM asset_faces WHERE face_id = ?", (face_id,))

    # threading.Thread(target=background_funs.trainModel, args=(f"{config['path']}/{username}/data/training",), daemon=True).start()

    conn.commit()
    return jsonify("Faces deleted successfully")

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
@app.route('/api/face/rename/<int:face_id>/<string:name>', methods=['GET'])
def rename_face(face_id, name):
    
    username = ""
    try:
        username = request.form['username']
    except:pass
    open_dbs(username)

    cursor.execute("UPDATE faces SET name = ? WHERE id = ?", (name, face_id))
    if cursor.rowcount == 0:
        return jsonify('Face not found'), 404
    conn.commit()
    return jsonify("Face renamed successfully")



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
@app.route('/api/search', methods=['GET'])
def search():
    # Logic to search the assets
    username = ""
    try:
        username = request.form['username']
    except:pass
    open_dbs(username)

    try:
        search = request.form['search']
    except:
        return jsonify('Bad request'), 400

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
    threading.Thread(target=run_background_script, daemon=True).start()
    print("Server started")
    serve(app, host="0.0.0.0", port=7251)
    # app.run(host="0.0.0.0", port=7251, debug=True) # multiple bg threads here

def run_background_script():
        os.system('python background.py')

if __name__ == '__main__':    # remove if karan is running
    start_this()

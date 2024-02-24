import background_funs
import threading
import os
import time
import json
import uuid
from PIL import Image, ExifTags
from datetime import datetime
import sqlite3
import cv2
import sys
from converters import convertAsset


config = None

def read_config():
    global config
    with open('config.json') as f:
        config = json.load(f)
    print("Config loaded")

# Establish a connection to the database

cursor = None
connection = None

def open_db(username):
    global config, connection, cursor
    if not os.path.exists(f'{config["path"]}/{username}/data.db'):
        os.system(f'python dbmake.py {username}')
    connection = sqlite3.connect(f'{config["path"]}/{username}/data.db', check_same_thread=False)
    cursor = connection.cursor()


# def recogniseFaces(image_path, image_id, username, connection):
#     # get the faces
#     train = background_funs.recogniseFaces(image_path, image_id, username, connection)
#     if train:
#         threading.Thread(target=background_funs.trainModel, args=(f"{username}/data/training",), daemon=False).start()


tags = set()
def bgtagging(loc, isVideo = False):
    global tags
    mtags = background_funs.tagImage(loc)
    if isVideo:
        tags.update(mtags)
        os.remove(f"{config['path']}/{u}/temp/{id}.png") 
    else:
        tags = set(mtags)

faces = set()
def bgface(loc, username, isVideo = False):
    global faces
    mfaces, training = background_funs.recogniseFaces(loc, username, config['path'], isVideo)
    if isVideo:
        for face in mfaces:
            faces.add(face['id'])
    else:
        faces = mfaces
    # if training:
    #     time.sleep(1)
    #     background_funs.trainModel(f"{config['path']}/{username}/data/training")

blurry = False
def bgblur(loc):
    global blurry
    blurry = background_funs.checkBlur(loc)
    
dones = []
cnt = 0
while True:
    read_config()
    for u in config['users']:

        # Faces model training once  -- remove when no need
        if u not in dones:
            background_funs.trainModel(f"{config['path']}/{u}/data/training")
            dones.append(u)

        print(f"Working on {u}")
        open_db(u)
        if not os.path.exists(f"{config['path']}/{u}/temp"):
            os.makedirs(f"{config['path']}/{u}/temp")
        if(os.listdir(f"{config['path']}/{u}/temp") == []):
            cnt+=1
            continue
        else:
            cnt = 0
        if(cnt==60):
            # find duplicates
            print("time to find duplicates")
            # os.system('python duplicates.py') # Thread-blocking call
            time.sleep(5)
            continue
        
        for asset in os.listdir(f'{config["path"]}/{u}/temp'):

            # check is asset is downloading?
            s = os.path.getsize(f"{config['path']}/{u}/temp/"+asset)
            time.sleep(1)
            if os.path.getsize(f"{config['path']}/{u}/temp/"+asset) < s:
                print("File is still downloading") 
                continue 
            
            img_typ = asset.rsplit('.')[-1]

            # Clear the vars
            tags = set()
            faces = set()
            blurry = False

            if img_typ == "mp4":
                vid_id = asset.rsplit('.')[0]
                print(vid_id)

                # Check video frame rate
                video_path = f"{config['path']}/{u}/temp/" + asset
                video = cv2.VideoCapture(video_path)

                # Loop through each frame
                while True:
                    ret, frame = video.read()  # ret = 1 if the video is captured; frame is the image
                    if not ret:
                        break

                    # Perform face recognition on every 5th frame - every 1 second
                    if video.get(cv2.CAP_PROP_POS_FRAMES) % 30 == 0:
                        # get the faces
                        p = background_funs.recogniseFaces(frame, u, config['path'], True)
                        print(p)
                        for person in p:
                            faces.add(person['id'])

                    elif video.get(cv2.CAP_PROP_POS_FRAMES) % 600 == 1:
                        # MAKE OBJECT DETECTION - using RAM - every 10 seconds           
                        id = uuid.uuid4().hex
                        cv2.imwrite(f"{config['path']}/{u}/temp/{id}.png", frame)
                        t = background_funs.tagImage(f"{config['path']}/{u}/temp/{id}.png")
                        tags.update(t)
                        os.remove(f"{config['path']}/{u}/temp/{id}.png")

                    # Calculate progress percentage
                    progress = video.get(cv2.CAP_PROP_POS_FRAMES) / video.get(cv2.CAP_PROP_FRAME_COUNT) * 100
                    # Create progress bar
                    bar_length = 20
                    filled_length = int(progress / 100 * bar_length)
                    bar = '█' * filled_length + '-' * (bar_length - filled_length)

                    # Print progress bar
                    sys.stdout.write(f"\rProgress: [{bar}] {progress:.2f}%")
                    sys.stdout.flush()
                
                print("video processing done")
                video.release()
                cv2.destroyAllWindows()

                # add tags to database
                try:
                    for tag in tags:
                        cursor.execute("INSERT INTO asset_tags (asset_id, tag_id) VALUES (?, ?)", (vid_id, tag))
                except:pass

                # add people to database
                for person in faces:
                    cursor.execute("INSERT INTO asset_faces (asset_id, face_id) VALUES (?, ?)", (vid_id, person))

                connection.commit()

                # Get year month date from video created exif data
                cursor.execute("SELECT created, compress FROM assets WHERE id = ?", (vid_id,))
                result = cursor.fetchone()
                # print("datetime = ", result)
                if result is not None:
                    date_time = result[0]
                    compress = result[1]
                else:
                    # Handle the case when no rows are returned
                    date_time = datetime.now()
                    compress = None
                try:
                    date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
                except:
                    date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')

                # save the video with preview
                background_funs.saveVideo(f"{config['path']}/{u}/temp/"+asset, vid_id, asset.rsplit(".")[-1], compress, f"{config['path']}/{u}/master", f"{config['path']}/{u}/preview", date_time.year, date_time.month, date_time.day)            
                
            
            elif img_typ == "png":

                image_id = asset.rsplit('.')[0]
                print(image_id)

                # get the tags - USE PYTHON 3.8.10 or 3.10.0
                tagsThread = threading.Thread(target=bgtagging, args=(f"{config['path']}/{u}/temp/"+asset,))
                tagsThread.start()

                # do face recog on bg thread
                faceThread = threading.Thread(target=bgface, args=(f"{config['path']}/{u}/temp/"+asset, u))
                faceThread.start()

                # do blur check on bg thread
                blurThread = threading.Thread(target=bgblur, args=(f"{config['path']}/{u}/temp/"+asset,))
                blurThread.start()
                        

                # Get year month date from image created exif data
                date_time = None

                img = Image.open(f"{config['path']}/{u}/temp/"+asset)
                exif_data = img.getexif()
                print(exif_data)
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

                tagsThread.join()
                faceThread.join()
                blurThread.join()

                # add date and time to database
                if date_time is not None:
                    cursor.execute("UPDATE assets SET created = ? WHERE id = ?", (date_time, image_id))
                else:
                    cursor.execute("SELECT created FROM assets WHERE id = ?", (image_id,))
                    result = cursor.fetchone()
                    if result is not None:
                        date_time = result[0]
                        try:
                            date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S')
                        except:
                            date_time = datetime.strptime(date_time, '%Y-%m-%d %H:%M:%S.%f')
                    else:
                        date_time = datetime.now()
                
                # add tags to database
                for r in tags:
                    # search tag in tags table and if presen get index else add to table and get index
                    cursor.execute("Select id from tags where tag = ?",(r,))
                    tag_id = cursor.fetchone()[0]

                    # add to assets_tags table
                    try:
                        cursor.execute("Insert into asset_tags values(?,?)",(image_id,tag_id))
                    except:pass
                    
                # add faces to database
                unk = False
                for p in faces:
                    face_id = p['id']
                    if(len(str(p['id'])) >= 32):
                        unk = True
                        cursor.execute("Insert into faces(name) values(?)",(p['id'],))
                        face_id = cursor.lastrowid
                        connection.commit()
                        print(f"face_id = {face_id}")

                        # Save image for training
                        path = os.path.join(f"{config['path']}/{u}/data/training", str(face_id), str(image_id)+str(face_id)+str(p['face'][0])+"-unprocessed.jpg")
                        # make directory if not present
                        os.makedirs(os.path.dirname(path), exist_ok=True)
                        # # Crop the image
                        # new_coords = p["face"].copy()
                        # new_coords[0] -= new_coords[2]*0.4  # Moving X to left by 40% width
                        # new_coords[2] *= 1.8  # Increasing width by 80%
                        # new_coords[1] -= new_coords[3]*0.4  # Moving Y to top by 40% height
                        
                        


                        print(p['face'])
                        w = round(p['face'][2]*0.4)
                        h = round(p['face'][3]*0.4)
                        image = cv2.imread(f"{config['path']}/{u}/temp/{asset}")
                        height, width, _ = image.shape
                        # Calculate the cropping boundaries
                        x1 = max(p['face'][0] - w, 0)
                        y1 = max(p['face'][1] - h, 0)
                        x2 = min(p['face'][0] + p['face'][2] + w, width)
                        y2 = min(p['face'][1] + p['face'][3] + h, height)
                        # Crop the image within the boundaries
                        cropped_image = image[y1:y2, x1:x2]
                        cv2.imwrite(path, cropped_image)

                        # Save image for showing
                        path = os.path.join(f"{config['path']}/{u}/data/face", str(face_id)+".webp")
                        # make directory if not presen t
                        os.makedirs(os.path.dirname(path), exist_ok=True)

                        # uses prev funs here then ->

                        # Calculate the size of the square crop
                        size = min(x2 - x1, y2 - y1)

                        # Crop the image into a square
                        # Calculate the center coordinates
                        center_x = (x1 + x2) // 2
                        center_y = (y1 + y2) // 2

                        # Calculate the half size of the square crop
                        half_size = size // 2

                        # Calculate the new cropping boundaries
                        x1 = center_x - half_size
                        y1 = center_y - half_size
                        x2 = center_x + half_size
                        y2 = center_y + half_size

                        # Crop the image at the center
                        cropped_image = image[y1:y2, x1:x2]

                        cv2.imwrite(path, cropped_image)
                        # cv2.imshow("face", cropped_image)
                        # cv2.waitKey(0)

                        cursor.execute("Insert into asset_faces(asset_id, face_id, x, y, w, h) values(?,?,?,?,?,?)",(int(image_id),int(face_id),int(p['face'][0]),int(p['face'][1]),int(p['face'][2]),int(p['face'][3])))
                        connection.commit()
                
                if (unk):
                    background_funs.trainModel(f"{config['path']}/{u}/data/training")

                # add blur to database
                cursor.execute("UPDATE assets SET blurry = ? WHERE id = ?", (blurry, image_id))
                connection.commit()

                # Get compress from database
                # TODO:
                #     compress = cursor.fetchone()[0]
                #                ~~~~~~~~~~~~~~~~~^^^
                # TypeError: 'NoneType' object is not subscriptable
                cursor.execute("SELECT compress FROM assets WHERE id = ?", (image_id,))
                compress = cursor.fetchone()[0]

                # save the image with preview
                background_funs.saveImage(f"{config['path']}/{u}/temp/"+asset, image_id, asset.rsplit(".")[-1], compress, f"{config['path']}/{u}/master", f"{config['path']}/{u}/preview", date_time.year, date_time.month, date_time.day)


            else:
                # date_time = None
                # img = Image.open(f"{config['path']}/{u}/temp/"+asset)
                # exif_data = img.getexif()
                # for tag_id in exif_data:
                #     tag = ExifTags.TAGS.get(tag_id, tag_id)
                #     data = exif_data.get(tag_id)

                #     # get the date and time from exif data using tag
                #     if tag == 'DateTimeOriginal':
                #         date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                #         print(f"Date and Time: {date_time}")
                #     elif tag == 'DateTimeDigitized':
                #         date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                #         print(f"Date and Time: {date_time}")
                #     elif tag == 'DateTime':
                #         date_time = datetime.strptime(data, '%Y:%m:%d %H:%M:%S')
                #         print(f"Date and Time: {date_time}")
                #     elif tag == 'GPSInfo':  # TODO: get location from GPSInfo
                #         pass
                
                # img.close()

                # # add date and time to database
                # print(f"Date and Time: {date_time}")
                # print(f"Asset: {asset}")
                # if date_time is not None:
                #     cursor.execute("UPDATE assets SET created = ? WHERE id = ?", (date_time, asset))
                #     connection.commit()
                
                # cursor.execute("SELECT created FROM assets WHERE id = ?", (asset,))
                # dt = cursor.fetchone()[0]
                # print(f"Date and Time: {dt}")

                
                print("Converting file type", img_typ)
                convertAsset(f"{config['path']}/{u}/temp/"+asset)
            
        time.sleep(2)
    time.sleep(5)
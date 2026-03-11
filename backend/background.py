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
import user_store


config = None

def read_config():
    global config
    if os.path.exists('config.json'):
        with open('config.json') as f:
            config = json.load(f)
    else:
        config = {"path": ""}
        with open('config.json', 'w') as f:
            json.dump(config, f)
    config.setdefault('path', "")
    # print("Config loaded")


def list_users():
    if not config.get('path'):
        return []
    try:
        return user_store.list_users(config['path'])
    except Exception as exc:
        print(f"Unable to load users for background worker: {exc}")
        return []

# Establish a connection to the database

cursor = None
connection = None

def open_db(username):
    global config, connection, cursor
    if not os.path.exists(f'{config["path"]}/{username}/data.db'):
        os.system(f'python backend/dbmake.py {username}')
    connection = sqlite3.connect(f'{config["path"]}/{username}/data.db', check_same_thread=False, timeout=30)
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
    for u in list_users():

        # Faces model training once  -- remove when no need
        if u not in dones:
            background_funs.trainModel(f"{config['path']}/{u}/data/training")
            dones.append(u)

        # print(f"Working on {u}")
        open_db(u)
        if not os.path.exists(f"{config['path']}/{u}/temp"):
            os.makedirs(f"{config['path']}/{u}/temp")
        
        if(cnt>=60):
            print("time to find duplicates")
            # find duplicates
            os.system('python backend/duplicates.py') # Thread-blocking call
            cnt = 0
            continue

        if(os.listdir(f"{config['path']}/{u}/temp") == []):
            cnt+=1
            # print(f"Background thread: No new files in {u}/temp - count: {cnt}")
            continue
        else:
            cnt = 0
        
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

                # add tags to database
                try:
                    for tag in tags:
                        cursor.execute("INSERT INTO asset_tags (asset_id, tag_id) VALUES (?, ?)", (vid_id, tag))
                except:pass

                # add people to database
                for person in faces:
                    try:
                        cursor.execute("INSERT INTO asset_faces (asset_id, face_id) VALUES (?, ?)", (vid_id, person))
                    except sqlite3.IntegrityError:
                        # Face already associated with this asset (UNIQUE constraint)
                        pass

                # add blur to database
                cursor.execute("UPDATE assets SET blurry = ? WHERE id = ?", (blurry, vid_id))

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

                # OCR Processing
                ocr_text = None
                ocr_triggers = {'advertisement', 'alphabet', 'article', 'atlas', 'bank card', 'banknote', 'banner', 'bible', 'bill', 'billboard', 'binder', 'blackboard', 'blog', 'book', 'book cover', 'bookmark', 'brand', 'business card', 'calendar', 'calligraphy', 'card', 'certificate', 'check', 'checkbook', 'checklist', 'comic', 'comic book', 'comic strip', 'computer monitor', 'computer screen', 'contract', 'credit card', 'currency', 'digital clock', 'diploma', 'document', 'dollar', 'fiction book', 'file', 'flipchart', 'flyer', 'font', 'form', 'graph', 'guide', 'handwriting', 'id photo', 'identity card', 'information desk', 'ink', 'inscription', 'invitation', 'journal', 'label', 'letter', 'letter logo', 'lettering', 'license', 'license plate', 'list', 'magazine', 'mailbox', 'manuscript', 'map', 'mark', 'menu', 'monitor', 'monument', 'movie poster', 'movie ticket', 'neon light', 'news', 'note', 'notebook', 'notepad', 'notepaper', 'notice', 'number', 'number icon', 'paper', 'paperback book', 'parchment', 'passbook', 'passport', 'phonebook', 'placard', 'plan', 'plaque', 'poetry', 'poker card', 'poster', 'poster page', 'prescription', 'print', 'printed page', 'publication', 'quote', 'receipt', 'recipe', 'record', 'road sign', 'scoreboard', 'screen', 'screenshot', 'sheet music', 'sign', 'signage', 'signal', 'signature', 'stamp', 'sticker', 'stop sign', 'street sign', 'symbol', 'text', 'text message', 'ticket', 'traffic sign', 'typewriter', 'website', 'wedding invitation', 'whiteboard', 'work card', 'writing'}
                # Check if any trigger word is in the tags (case-insensitive)
                if not tags.isdisjoint(ocr_triggers):
                    print(f"OCR Triggered for {image_id} due to tags: {tags.intersection(ocr_triggers)}")
                    ocr_text = background_funs.extract_text(f"{config['path']}/{u}/temp/"+asset)
                    if ocr_text:
                        cursor.execute("UPDATE assets SET ocr_text = ? WHERE id = ?", (ocr_text, image_id))
                        cursor.execute("INSERT INTO images_ocr_fts (image_id, ocr_text) VALUES (?, ?)", (image_id, ocr_text))
                        connection.commit()
                        print(f"OCR Text saved for {image_id}")

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
                    tag_id = []
                    try:
                        tag_id = cursor.fetchone()[0]
                    except:pass
                    # add to assets_tags table
                    try:
                        cursor.execute("Insert into asset_tags values(?,?)",(image_id,tag_id))
                    except:pass
                    
                # add faces to database
                unk = False
                print(faces)
                for p in faces:
                    face_id = p['id']
                    
                    # CASE 1: New/Unknown Face (UUID)
                    if(len(str(p['id'])) >= 32):
                        # Mark as unverified (-1)
                        cursor.execute("Insert into faces(name) values(?)",(p['id'],))
                        face_id = cursor.lastrowid
                        connection.commit()
                        print(f"New face created: {face_id} (Unverified)")

                        # Save image for training (Required for new faces to establish identity)
                        try:
                            image = cv2.imread(f"{config['path']}/{u}/temp/{asset}")
                            if image is not None:
                                height, width, _ = image.shape
                                
                                # Padding logic (40%)
                                w_pad = round(p['face'][2]*0.4)
                                h_pad = round(p['face'][3]*0.4)
                                
                                x1 = max(p['face'][0] - w_pad, 0)
                                y1 = max(p['face'][1] - h_pad, 0)
                                x2 = min(p['face'][0] + p['face'][2] + w_pad, width)
                                y2 = min(p['face'][1] + p['face'][3] + h_pad, height)
                                
                                cropped_image = image[y1:y2, x1:x2]
                                
                                # Save for training
                                path = os.path.join(f"{config['path']}/{u}/data/training", str(face_id), str(image_id)+str(face_id)+str(p['face'][0])+"-unprocessed.jpg")
                                os.makedirs(os.path.dirname(path), exist_ok=True)
                                cv2.imwrite(path, cropped_image)

                                # Save for showing (Thumbnail)
                                path_thumb = os.path.join(f"{config['path']}/{u}/data/face", str(face_id)+".webp")
                                os.makedirs(os.path.dirname(path_thumb), exist_ok=True)
                                
                                # Square crop for thumbnail
                                size = min(x2 - x1, y2 - y1)
                                center_x = (x1 + x2) // 2
                                center_y = (y1 + y2) // 2
                                half_size = size // 2
                                tx1 = center_x - half_size
                                ty1 = center_y - half_size
                                tx2 = center_x + half_size
                                ty2 = center_y + half_size
                                thumb_image = image[ty1:ty2, tx1:tx2]
                                cv2.imwrite(path_thumb, thumb_image)
                                
                                # Flag to trigger retraining
                                unk = True
                        except Exception as e:
                            print(f"Error saving new face training data: {e}")

                        try:
                            cursor.execute("Insert into asset_faces(asset_id, face_id, x, y, w, h, verified) values(?,?,?,?,?,?,?)",(int(image_id),int(face_id),int(p['face'][0]),int(p['face'][1]),int(p['face'][2]),int(p['face'][3]), -1))
                            connection.commit()
                        except sqlite3.IntegrityError:
                            pass
                    
                    # CASE 2: Known Face
                    else:
                        dist = p.get('cosine', 1.0)
                        verified_status = 0 # Default: Low confidence (0.15 < dist <= 0.30)
                        
                        # High Confidence Check (Auto-Verify)
                        if dist <= 0.15:
                            verified_status = 1
                            print(f"High confidence match ({dist}) for face {face_id}. Auto-verifying.")
                            
                            # Add to training data
                            try:
                                image = cv2.imread(f"{config['path']}/{u}/temp/{asset}")
                                if image is not None:
                                    height, width, _ = image.shape
                                    
                                    # Padding logic (40%)
                                    w_pad = round(p['face'][2]*0.4)
                                    h_pad = round(p['face'][3]*0.4)
                                    
                                    x1 = max(p['face'][0] - w_pad, 0)
                                    y1 = max(p['face'][1] - h_pad, 0)
                                    x2 = min(p['face'][0] + p['face'][2] + w_pad, width)
                                    y2 = min(p['face'][1] + p['face'][3] + h_pad, height)
                                    
                                    cropped_image = image[y1:y2, x1:x2]
                                    
                                    # Save for training
                                    path = os.path.join(f"{config['path']}/{u}/data/training", str(face_id), str(image_id)+str(face_id)+str(p['face'][0])+"-unprocessed.jpg")
                                    os.makedirs(os.path.dirname(path), exist_ok=True)
                                    cv2.imwrite(path, cropped_image)
                                    
                                    # Flag to trigger retraining
                                    unk = True
                            except Exception as e:
                                print(f"Error saving training data: {e}")

                        try:
                            cursor.execute("Insert into asset_faces(asset_id, face_id, x, y, w, h, verified) values(?,?,?,?,?,?,?)",(int(image_id),int(face_id),int(p['face'][0]),int(p['face'][1]),int(p['face'][2]),int(p['face'][3]), verified_status))
                            connection.commit()
                        except sqlite3.IntegrityError:
                            pass
                
                # Trigger retraining if new high-confidence data was added
                if unk:
                    threading.Thread(target=background_funs.trainModel, args=(f"{config['path']}/{u}/data/training",)).start()
                        
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

                # Not needed as before face verification it auto-updates model
                
                # if (unk):
                #     background_funs.trainModel(f"{config['path']}/{u}/data/training")

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
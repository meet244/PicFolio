from deepface import DeepFace
import uuid
import os
import numpy as np
import matplotlib.pyplot as plt
from gradio_client import Client
import warnings
import difPy
import cv2
from PIL import Image
import time
import threading
from matplotlib import pyplot as plt
import logging
from blur_detection import estimate_blur
from blur_detection import fix_image_size
from blur_detection import pretty_blur_map
import cv2
from PIL import Image
import os
import logging
import subprocess
import shutil
from moviepy.editor import VideoFileClip
import cv2
import imageio


# Training Face Recognition Model
def trainModel(path) -> None:
    """
    This function trains the model and saves it to the specified path.
    
    Parameters:
    path (str): The path to the directory where images are kept and the model also will be saved here.

    Returns:
    None
    """
    # create folders if not present
    if not os.path.exists(path):
        os.makedirs(path, exist_ok=True)
        return
    # FaceCrop images using opencv backend
    for dir in os.listdir(path):
        if("pkl" in dir):continue
        for file in os.listdir(os.path.join(path, dir)):
            if "-unprocessed" in file:
                try:
                    face = DeepFace.extract_faces(
                        img_path=os.path.join(path, dir, file),
                        detector_backend='opencv',
                        enforce_detection=True,
                    )
                    face = face[0]
                    x = face['facial_area']['x']
                    y = face['facial_area']['y']
                    w = face['facial_area']['w']
                    h = face['facial_area']['h']

                    cv2.imwrite(os.path.join(path,dir, file), cv2.imread(os.path.join(path,dir, file))[y:y+h, x:x+w])

                    os.rename(os.path.join(path,dir, file), os.path.join(path,dir, file).replace("-unprocessed", ''))
                    # cv2.imshow("face", cv2.imread(os.path.join(path,dir, file))[y:y+h, x:x+w])
                    # cv2.waitKey(0)
                except Exception as e:
                    print(e) 

    # Delete previous model
    try:
        os.remove(os.path.join(path,'representations_facenet512.pkl'))
        # print("NOT REMOVING Pickle")
    except:
        pass

    # Train the model
    try:
        DeepFace.find(
            img_path = np.zeros((100, 100, 3), dtype=np.uint8),
            db_path = path, 
            model_name = "Facenet512",
            # detector_backend=b,
            enforce_detection=False,
            # silent=True,
        )
    except Exception as e:
        print(e)

# Face Recognition
# name of person should be less than 32 characters
def recogniseFaces(image_path, username, configPath, isVideo = False) -> bool:
    """
    This function loads an image from the provided path, detects faces in the image.

    Parameters:
    image_path (str): The path to the image file.

    Returns:
    bool : True if the training is required, False otherwise.
    """
    while not os.path.exists(f"{configPath}/{username}/data/training/representations_facenet512.pkl"):
        folders = [folder for folder in os.listdir(f"{configPath}/{username}/data/training") if os.path.isdir(folder)]
        if(len(folders) == 0):
            print("No faces found")
            break
        print("Waiting for model to train")
        time.sleep(10)
    unknownPeople = False
    dfs = []
    try:
        dfs = DeepFace.find(
            img_path = image_path,
            db_path = f"{configPath}/{username}/data/training",
            model_name = "Facenet512",
            enforce_detection=False,
            silent=True,
            detector_backend='retinaface'   # use retina to detect images and save | use opencv(def) to train model from cropped ones efficiency almost similar
        )
    except Exception as e:
        print(e)
        unknownPeople = True
    # print(dfs)
    people = []
    # iterate over the list of dataframes
    for df in dfs:
        # check if the dataframe is empty
        if df.empty or len(dfs) == 0:
            unknownPeople = True
            continue

        p = {}
        #iterate over the rows of the dataframe
        for index, row in df.iterrows():
            #check if id is already in people list
            dist = 0.0
            if index == 0:
                p['id'] = row["identity"].split("\\")[-1].split("/")[0]
                p['face'] = [row['source_x'],row['source_y'],row['source_w'],row['source_h']]
                try:
                    dist = row['Facenet512_cosine']
                except Exception as e:
                    dist = row['distance']
                p['cosine'] = dist
            elif p['cosine'] > dist:
                        p['id'] = row["identity"].split("\\")[-1].split("/")[0]
                        p['face'] = [row['source_x'],row['source_y'],row['source_w'],row['source_h']]
                        p['cosine'] = dist
        people.append(p)
    
    if isVideo:
        return people

    print("unknown = ", unknownPeople)
    if unknownPeople:
        faces = DeepFace.extract_faces(
                img_path=image_path,
                detector_backend='retinaface',
                enforce_detection=False,
            )
        for face in faces:
            # check if face is already in people list
            if(face['confidence'] < 0.9):continue
            if(list(face['facial_area'].values()) not in [i['face'] for i in people]):
                people.append({'id':str(uuid.uuid4().hex),'face':list(face['facial_area'].values()),'cosine':0.0})
    print(people)
    return people, unknownPeople and len(people) > 0

    # Save the faces in sqlite
    # cursor = connection.cursor()
    # for p in people:
    #     face_id = p['id']
    #     if(len(str(p['id'])) >= 32):
    #         cursor.execute("Insert into faces(name) values(?)",(p['id'],))
    #         face_id = cursor.lastrowid
    #         print(f"face_id = {face_id}")

    #         # Save image for training
    #         path = os.path.join(f"{username}/data/training", str(face_id), str(image_id)+str(face_id)+str(p['face'][0])+"-unprocessed.jpg")
    #         # make directory if not present
    #         os.makedirs(os.path.dirname(path), exist_ok=True)
    #         # Crop the image
    #         w = round(p['face'][2]*0.25)
    #         h = round(p['face'][3]*0.25)
    #         image = cv2.imread(image_path)
    #         height, width, _ = image.shape
    #         # Calculate the cropping boundaries
    #         x1 = max(p['face'][0] - h, 0)
    #         y1 = max(p['face'][1] - w, 0)
    #         x2 = min(p['face'][0] + p['face'][2] + h, width)
    #         y2 = min(p['face'][1] + p['face'][3] + w, height)
    #         # Crop the image within the boundaries
    #         cropped_image = image[y1:y2, x1:x2]
    #         cv2.imwrite(path, cropped_image)

    #         # Save image for showing
    #         path = os.path.join(f"{username}/data/face", str(face_id)+".webp")
    #         # make directory if not presen t
    #         os.makedirs(os.path.dirname(path), exist_ok=True)

    #         # uses prev funs here then ->

    #         # Calculate the size of the square crop
    #         size = min(x2 - x1, y2 - y1)

    #         # Crop the image into a square
    #         # Calculate the center coordinates
    #         center_x = (x1 + x2) // 2
    #         center_y = (y1 + y2) // 2

    #         # Calculate the half size of the square crop
    #         half_size = size // 2

    #         # Calculate the new cropping boundaries
    #         x1 = center_x - half_size
    #         y1 = center_y - half_size
    #         x2 = center_x + half_size
    #         y2 = center_y + half_size

    #         # Crop the image at the center
    #         cropped_image = image[y1:y2, x1:x2]

    #         cv2.imwrite(path, cropped_image)
    #         # cv2.imshow("face", cropped_image)
    #         # cv2.waitKey(0)

    #     cursor.execute("Insert into asset_faces(asset_id, face_id, x, y, w, h) values(?,?,?,?,?,?)",(int(image_id),int(face_id),int(p['face'][0]),int(p['face'][1]),int(p['face'][2]),int(p['face'][3])))

    # return unknownPeople and len(people) > 0


# Blur Detection
def tagImage(image_path) -> None:
    """
    Calls an API to predict the content of an image.

    Parameters:
    image_url (str): The URL of the image.

    Returns:
    list: A list of predicted labels for the image.
    """
    try:
        client = Client("https://xinyu1205-recognize-anything.hf.space/")
        result = client.predict(image_path, fn_index=2)
        result = result[0].split(" | ")
        print(result)
        return result
    except Exception as e:
        print(e)
        return []
        # # get cursor
        # cursor = connection.cursor()

        # for r in result:
        #     # search tag in tags table and if presen get index else add to table and get index
        #     cursor.execute("Select id from tags where tag = ?",(r,))
        #     tag_id = cursor.fetchone()[0]

        #     # add to assets_tags table
        #     cursor.execute("Insert into asset_tags values(?,?)",(image_id,tag_id))

#CHECK
# Blur Detection
def checkBlur(image_path, threshold=4.5) -> None:
    """
    Checks if an image is blurry.

    Parameters:
    image_path (str): The path to the image file.

    Returns:
    bool: True if the image is blurry, False otherwise.
    """
    image = cv2.imread(image_path)
    if image is None:
        logging.warning(f'warning! failed to read image from {image_path}; skipping!')
        return

    image = fix_image_size(image)
    blur_map, score, blurry = estimate_blur(image, threshold=threshold)
    print(f"Blur score: {score}")
    print(f"Blurry: {blurry}")
    return blurry
    # edit to assets table
    # cursor = connection.cursor()
    # cursor.execute("Update assets set blurry = ? where id = ?",(blurry,image_id))


def saveImage(image_loc, name, format, compress, mainPath, previewPath, year, month, date, max_size=250):
    """
    Saves an image to the specified directory with the given parameters.

    Parameters:
    image (PIL.Image.Image): The image to be saved.
    mainPath (str): The path to the main directory where the image will be saved.
    previewPath (str): The path to the preview directory where the resized image will be saved.
    year (int): The year of the image.
    month (int): The month of the image.
    date (int): The date of the image.
    quality_op (int): The quality of the resized image. Defaults to 70.
    max_size (int): The maximum size of the resized image. Defaults to 250.

    Returns:
    None

    This function saves the original image to the main directory with a unique name generated using UUID.
    It also resizes the image while maintaining the aspect ratio and saves the resized image to the preview directory as a WebP file with lower quality.
    The quality of the output image and the minimum resolution can be adjusted using the `quality_op` and `max_size` variables respectively.
    """
    
    os.makedirs(os.path.dirname(os.path.join(mainPath, str(year), str(month), str(date), name)), exist_ok=True)
    image = Image.open(image_loc)
    if compress:
        width = image.width
        height = image.height
        if width * height > 16000000:
            # resize image to 16MP
            print("Resizing image to 16MP")
            # calculate width and height under 16MP
            while width * height > 16000000:
                width = width * 0.95
                height = height * 0.95
            image = image.resize((int(width), int(height)), Image.LANCZOS)
        image.save(os.path.join(mainPath, str(year), str(month), str(date), name) + "." + format, optimize=True, quality=70)
    else:
        image.save(os.path.join(mainPath, str(year), str(month), str(date), name) + "." + format)

    # Calculate the new size while maintaining the aspect ratio
    original_width, original_height = image.size

    aspect_ratio = original_width / original_height

    if original_width < original_height:
        new_width = max_size
        new_height = int(max_size / aspect_ratio)
    else:
        new_height = max_size
        new_width = int(max_size * aspect_ratio)

    # Resize the image for preview
    resized_image = image.resize((new_width, new_height), Image.LANCZOS)

    os.makedirs(os.path.dirname(os.path.join(previewPath, str(year), str(month), str(date), name)), exist_ok=True)
    output_path = os.path.join(previewPath, str(year), str(month), str(date), name) + ".webp"

    # Save the resized image as WebP with lower quality
    resized_image.save(output_path, 'WEBP', quality=70)

    print(f"Image saved to {output_path}")

    image.close()
    os.remove(image_loc)


def saveVideo(video_loc, name, format, compress, mainPath, previewPath, year, month, date):
    """
    Saves a video to the specified directory with the given parameters.

    Parameters:
    video_loc (str): The path to the video file.
    mainPath (str): The path to the main directory where the video will be saved.
    previewPath (str): The path to the preview directory where the resized video will be saved.
    year (int): The year of the video.
    month (int): The month of the video.
    date (int): The date of the video.
    quality_op (int): The quality of the resized video. Defaults to 70.
    max_size (int): The maximum size of the resized video. Defaults to 250.

    Returns:
    None

    This function saves the original video to the main directory with a unique name generated using UUID.
    It also resizes the video while maintaining the aspect ratio and saves the resized video to the preview directory as a WebP file with lower quality.
    The quality of the output video and the minimum resolution can be adjusted using the `quality_op` and `max_size` variables respectively.
    """
    
    os.makedirs(os.path.join(mainPath, str(year), str(month), str(date)), exist_ok=True)
    if compress:
        t_file = video_loc.replace(f"{name}.mp4", "temp.mp4")
        
        # Open input video path
        video_capture = cv2.VideoCapture(video_loc)

        # Get the video frame width, height, and frame rate
        frame_width = int(video_capture.get(cv2.CAP_PROP_FRAME_WIDTH))
        frame_height = int(video_capture.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # check if video definition like 1080p, 720p...
        new_height = frame_height
        new_width = frame_width
        if (frame_height > 1080 or frame_width > 1080):
            if frame_width > frame_height:
                new_width = 1080
                new_height = int(new_width / (frame_width / frame_height))
            else:
                new_height = 1080
                new_width = int(new_height * (frame_width / frame_height))


        fps = int(video_capture.get(cv2.CAP_PROP_FPS))

        # Create video writer object with compression
        fourcc = cv2.VideoWriter.fourcc(*'mp4v')
        if new_height!=None:
            output_video = cv2.VideoWriter(t_file, fourcc, fps, (new_width, new_height), isColor=True)
        else:
            output_video = cv2.VideoWriter(t_file, fourcc, fps, (frame_width, frame_height), isColor=True)
        # Loop through the frames and write them to the output video
        while True:
            ret, frame = video_capture.read()
            if not ret:
                break
            if new_height!=None:
                frame = cv2.resize(frame, (new_width, new_height))
            
            # Write the frame to the output video
            output_video.write(frame)

        # Release video objects
        video_capture.release()
        output_video.release()

        # Get the audio from the original video
        audio_clip = VideoFileClip(video_loc).audio

        # Write the compressed video frames with audio
        print(t_file)
        compressed_video = VideoFileClip(t_file)
        compressed_video = compressed_video.set_audio(audio_clip)
        compressed_video.write_videofile(os.path.join(mainPath, str(year), str(month), str(date), name) + "."+format, codec='libx264', audio_codec='aac')
        try:audio_clip.close()
        except:pass
        try:compressed_video.close()
        except:pass

        # Remove the temporary file
        os.remove(t_file)

    else:
        # save original in new folder
        shutil.copyfile(video_loc, os.path.join(mainPath, str(year), str(month), str(date), name) + "."+format)

    # save gif in new folder
    os.makedirs(os.path.join(previewPath, str(year), str(month), str(date)), exist_ok=True)
    op = os.path.join(previewPath, str(year), str(month), str(date), name) + ".mp4"

    convert_video_to_gif(os.path.join(mainPath, str(year), str(month), str(date), name) + "."+format, op, previewPath, year, month, date)
    print(f"Video saved to {os.path.join(mainPath, str(year), str(month), str(date), name) + '.' + format}")

    # remove video from temp
    os.remove(video_loc)

# Similar Images at duplicates.py
    
def convert_video_to_gif(input_video_path, output_path, previewPath, year, month, date):
    # Read video
    cap = cv2.VideoCapture(input_video_path)

    # Get video properties
    width = int(cap.get(3))
    height = int(cap.get(4))
    fps = cap.get(5)
    total_frames = int(cap.get(7))

    # Calculate new width and height while maintaining aspect ratio
    if width > height:
        new_width = 250
        new_height = int((new_width / width) * height)
    else:
        new_height = 250
        new_width = int((new_height / height) * width)

    # Create VideoWriter object for resized video
    resized_video_writer = cv2.VideoWriter(os.path.join(previewPath, str(year), str(month), str(date), 'resized_video.mp4'), cv2.VideoWriter_fourcc(*'mp4v'), fps, (new_width, new_height))

    # Read and resize frames, write to resized video
    for _ in range(total_frames):
        ret, frame = cap.read()
        if not ret:
            break
        resized_frame = cv2.resize(frame, (new_width, new_height))
        resized_video_writer.write(resized_frame)

    # Release VideoWriter object
    resized_video_writer.release()

    # Release the original video capture object
    cap.release()

    # Create VideoCapture object for resized video
    resized_cap = cv2.VideoCapture(os.path.join(previewPath, str(year), str(month), str(date), 'resized_video.mp4'))

    # Calculate frames to keep for the first 10 seconds
    frames_to_keep = int(fps * 10)

    # Create VideoWriter object for trimmed video
    trimmed_video_writer = cv2.VideoWriter(output_path), cv2.VideoWriter_fourcc(*'mp4v'), fps, (new_width, new_height)

    # Read and write frames for the first 10 seconds
    for i in range(frames_to_keep):
        ret, frame = resized_cap.read()
        if not ret:
            break
        trimmed_video_writer.write(frame)

    # # Release VideoWriter object for the trimmed video
    trimmed_video_writer.release()

    # # Release VideoCapture object for the resized video
    resized_cap.release()

    # # Create GIF from trimmed video using OpenCV
    # # gif_frames = []
    # trimmed_cap = cv2.VideoCapture(output_path)
    # for _ in range(frames_to_keep):
    #     ret, frame = trimmed_cap.read()
    #     if not ret:
    #         break
    #     # Convert BGR to RGB
    #     # frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
    #     # gif_frames.append(frame_rgb)

    # # Save GIF using imageio with infinite loop
    # # imageio.mimsave(output_path, gif_frames, fps=fps, loop=0)

    # # Release VideoCapture object for the trimmed video
    # trimmed_cap.release()

    # Clean up temporary files
    cv2.destroyAllWindows()

    os.remove(os.path.join(previewPath, str(year), str(month), str(date), 'resized_video.mp4'))
    # os.remove(os.path.join(previewPath, str(year), str(month), str(date), 'trimmed_video.mp4'))


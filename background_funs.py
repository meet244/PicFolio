# All functions from functions.ipynb are here in production ready form

from deepface import DeepFace
import uuid
import os
import numpy as np
import matplotlib.pyplot as plt
from gradio_client import Client
import warnings
import difPy
import cv2
import time
from matplotlib import pyplot as plt
import logging
from blur_detection import estimate_blur
from blur_detection import fix_image_size
from blur_detection import pretty_blur_map

# Training Face Recognition Model
# Checks Pending
def trainModel(path) -> None:
    """
    This function trains the model and saves it to the specified path.
    
    Parameters:
    path (str): The path to the directory where images are kept and the model also will be saved here.

    Returns:
    None
    """
    # Delete previous model
    try:
        os.remove(os.path.join(path,'representations_facenet512.pkl'))
    except:
        pass

    # Train the model
    DeepFace.find(
        img_path = np.zeros((100, 100, 3), dtype=np.uint8),
        db_path = path, 
        model_name = "Facenet512",
        enforce_detection=False,
        silent=True,
    )

# Face Recognition
# sql check required
# name of person should be less than 32 characters
def recogniseFaces(image_path, image_id, connection) -> None:
    """
    This function loads an image from the provided path, detects faces in the image.

    Parameters:
    image_path (str): The path to the image file.

    Returns:
    None

    """
    unknownPeople = False
    dfs = DeepFace.find(
        img_path = image_path,
        db_path = r"data\faces",
        model_name = "Facenet512",
        enforce_detection=False,
        silent=True,
        detector_backend='retinaface'   # use retina to detect images and save | use opencv(def) to train model from cropped ones efficiency almost similar
    )
    # print(dfs)
    people = []
    # iterate over the list of dataframes
    for df in dfs:
        # check if the dataframe is empty
        if df.empty:
            unknownPeople = True
            continue

        p = {}
        #iterate over the rows of the dataframe
        for index, row in df.iterrows():
            #check if id is already in people list
            if index == 0:
                p['id'] = row["identity"].split("\\")[-1].split("/")[0]
                p['face'] = [row['source_x'],row['source_y'],row['source_w'],row['source_h']]
                p['cosine'] = row['Facenet512_cosine']
            elif p['cosine'] > row['Facenet512_cosine']:
                        p['id'] = row["identity"].split("\\")[-1].split("/")[0]
                        p['face'] = [row['source_x'],row['source_y'],row['source_w'],row['source_h']]
                        p['cosine'] = row['Facenet512_cosine']
        people.append(p)
    
    if unknownPeople:
        faces = DeepFace.extract_faces(
                img_path=image_path,
                detector_backend='retinaface',
                enforce_detection=False,
            )
        for face in faces:
            # check if face is already in people list
            if(list(face['facial_area'].values()) not in [i['face'] for i in people]):
                people.append({'id':str(uuid.uuid4().hex),'face':list(face['facial_area'].values()),'cosine':0.0})
    print(people)
    # Save the faces in sqlite
    cursor = connection.cursor()
    for p in people:
        face_id = p['id']
        if(len(p['id']) >= 32):
            cursor.execute("Insert into faces(name) values(?)",(p['id'],))
            face_id = cursor.lastrowid
            # TODO: add face to dataset - in files

        cursor.execute("Insert into asset_faces(asset_id, face_id, x, y, w, h) values(?,?,?,?,?,?)",(int(image_id),int(face_id),int(p['face'][0]),int(p['face'][1]),int(p['face'][2]),int(p['face'][3])))


# Blur Detection
# sql check required
def tagImage(image_path, image_id, connection) -> None:
    """
    Calls an API to predict the content of an image.

    Parameters:
    image_url (str): The URL of the image.

    Returns:
    list: A list of predicted labels for the image.
    """
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        client = Client("https://xinyu1205-recognize-anything.hf.space/")
        result = client.predict(image_path, fn_index=2)
        result = result[0].split(" | ")
        print(result)
        
        # get cursor
        cursor = connection.cursor()

        for r in result:
            # search tag in tags table and if presen get index else add to table and get index
            cursor.execute("Select id from tags where tag = ?",(r,))
            tag_id = cursor.fetchone()[0]

            # add to assets_tags table
            cursor.execute("Insert into asset_tags values(?,?)",(image_id,tag_id))

# Blur Detection
# sql check required
def checkBlur(image_path, image_id, connection, threshold=100.0) -> None:
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
        return False

    image = fix_image_size(image)
    blur_map, score, blurry = estimate_blur(image, threshold=threshold)

    # edit to assets table
    cursor = connection.cursor()
    cursor.execute("Update assets set blurry = ? where id = ?",(blurry,image_id))

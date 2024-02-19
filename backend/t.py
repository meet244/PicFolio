import os
import requests
from deepface import DeepFace


DeepFace.stream(
    model_name = "Facenet512",
    db_path = r"F:\Picfolio\meet244\data\training"
    )

exit()

for d in os.listdir(r'D:\Picfolio\meet244\data\training'):
    if 'pkl' in d:
        continue
    unpro = 0
    for t in os.listdir(fr'D:\Picfolio\meet244\data\training\{d}'):
        if 'unprocessed' in t:
            os.remove(fr'D:\Picfolio\meet244\data\training\{d}\{t}')
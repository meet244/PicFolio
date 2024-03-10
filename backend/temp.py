import cv2
import os
import PIL.Image

# Load the cascade
face_cascade=cv2.CascadeClassifier('tools/haarcascade_frontalface_default.xml')

# Read the input image
for i in os.listdir(r'F:\Picfolio\meet244\data\face'):
    
    img = cv2.imread(r'F:\Picfolio\meet244\data\face\{}'.format(i))

    # Detect faces
    faces = face_cascade.detectMultiScale(img, 1.1, 4)

    # Draw rectangle around the faces
    for (x, y, w, h) in faces:
        cv2.rectangle(img, (x, y), (x+w, y+h), (255, 0, 0), 2)
    # Display the output
    cv2.imshow('img', img)
    cv2.waitKey()
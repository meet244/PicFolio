from flask import Flask, request
from PIL import Image
from PIL.ExifTags import TAGS
import os

app = Flask(__name__)

@app.route('/upload', methods=['POST'])
def upload_image():
    # Check if the post request has the file part
    if 'image' not in request.files:
        return 'No image uploaded'

    image_file = request.files['image']

    # Save the image to a temporary file
    image_filename = image_file.filename
    image_path = os.path.join(image_filename)
    image_file.save(image_path)

    # Open the image and get the creation date
    with Image.open(image_path) as image:
        # creation_date = image.getexif()
        exif_data = image.getexif()

        exif_info = {TAGS.get(k, k): v for k, v in exif_data.items()}
        for key, value in exif_info.items():
            print(f"{key}: {value}")

        # print(creation_date)
        # creation_date = image.getexif().get(IMAGE_CREATION_DATE)
        # print(f'Image creation date: {creation_date}')

    # Save the image to a permanent file
    saved_image_path = os.path.join(image_filename)
    os.rename(image_path, saved_image_path)

    return 'Image uploaded and saved successfully'

if __name__ == '__main__':
    app.run(debug=True)

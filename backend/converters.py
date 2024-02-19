
import pillow_avif 
from PIL import Image, ExifTags
import os
from moviepy.editor import VideoFileClip
from moviepy.editor import VideoFileClip
from  heic2png import HEIC2PNG  # pip install heic2png


# change image to PNG

def changeImageToPNG(image_path):
    # Open the image
    image = Image.open(image_path)

    # Preserve the original orientation using exif information
    try:
        for orientation in ExifTags.TAGS.keys():
            if ExifTags.TAGS[orientation] == 'Orientation':
                exif = dict(image._getexif().items())

                if exif[orientation] == 3:
                    image = image.rotate(180, expand=True)
                elif exif[orientation] == 6:
                    image = image.rotate(270, expand=True)
                elif exif[orientation] == 8:
                    image = image.rotate(90, expand=True)
    except (AttributeError, KeyError, IndexError):
        # Cases: image doesn't have EXIF data
        pass

    # Convert the image to RGB mode
    image = image.convert('RGB')

    # Save the image as PNG with the original rotation
    image_name = os.path.splitext(os.path.basename(image_path))[0]
    new_image_path = os.path.join(os.path.dirname(image_path), f"{image_name}.png")
    image.save(new_image_path, 'PNG')
                

def convertHEICtoPNG(image_path):
    heic_img = HEIC2PNG(image_path, quality=100)  # Specify the quality of the converted image
    heic_img.save(output_image_file_path=image_path.replace('.heic', '.png'))
    
    
def convertImage(path):
    image_path = path
    try:
        if image_path.endswith('.heic'):
            convertHEICtoPNG(image_path)
        else:
            changeImageToPNG(image_path)
        os.remove(image_path)
    except:
        print(f"Error converting image = {image_path}")
        # os.remove(image_path)


# change video to MP4
    
def changeVideoToMP4(video_path):
    video_name = os.path.splitext(os.path.basename(video_path))[0]
    new_video_path = os.path.join(os.path.dirname(video_path), f"{video_name}.mp4")
    clip = VideoFileClip(video_path)
    clip.write_videofile(new_video_path, codec='libx264', audio_codec='aac')
    clip.close()


def convertVideo(path):
    video_path = path
    try:
        changeVideoToMP4(video_path)
        os.remove(video_path)
    except Exception as e:
        # print(e)
        print(f"Error converting video = {video_path}")
        # os.remove(video_path)

def convertAsset(path):
    end = path.split('.')[-1].lower()
    if end in ('jpg', 'jpeg', 'avif', 'heic', 'ttif', 'webp', 'jfif'):
        convertImage(path)
    else:
        convertVideo(path)
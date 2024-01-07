from PIL import Image, ExifTags
import os

#params to play with
# quality of output image
quality_op = 100
# minimum h or w resolution
max_size = 250

# Load the original PNG image
input_path = r'C:\Users\meet2\Downloads\IMG_20211003_163627.jpg'
output_path = r'C:\Users\meet2\Downloads\small.webp'

# Open the image
original_image = Image.open(input_path)

# Preserve the orientation of the original image
try:
    for orientation in ExifTags.TAGS.keys():
        if ExifTags.TAGS[orientation] == 'Orientation':
            break
    exif = dict(original_image._getexif().items())
    if exif[orientation] == 3:
        original_image = original_image.rotate(180, expand=True)
    elif exif[orientation] == 6:
        original_image = original_image.rotate(270, expand=True)
    elif exif[orientation] == 8:
        original_image = original_image.rotate(90, expand=True)
except (AttributeError, KeyError, IndexError):
    # Cases: image has no exif data or orientation information
    pass

# Calculate the new size while maintaining the aspect ratio
original_width, original_height = original_image.size

aspect_ratio = original_width / original_height

if original_width < original_height:
    new_width = max_size
    new_height = int(max_size / aspect_ratio)
else:
    new_height = max_size
    new_width = int(max_size * aspect_ratio)

# Resize the image
resized_image = original_image.resize((new_width, new_height), Image.ANTIALIAS)

# Save the resized image as WebP with lower quality
resized_image.save(output_path, 'WEBP', quality=quality_op)  # You can adjust the quality value as needed

print(f"Image saved to {output_path}")

original_size_kb = os.path.getsize(input_path) / 1024 
compressed_size_kb = os.path.getsize(output_path) / 1024

print(f"Original image size: {original_size_kb:.2f} KB")
print(f"Compressed image size: {compressed_size_kb:.2f} KB")

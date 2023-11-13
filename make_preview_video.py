from moviepy.video.io.VideoFileClip import VideoFileClip
from moviepy.video.io.ffmpeg_tools import ffmpeg_extract_subclip
from PIL import Image

def extract_frame(video_path, output_path, frame_time=0.0, quality=70):
    # Extract a subclip containing a single frame at the specified time
    clip = VideoFileClip(video_path)
    frame = clip.get_frame(frame_time)

    # Convert the frame to a Pillow Image
    frame_image = Image.fromarray(frame)

    # Save the frame as WebP with the desired quality
    frame_image.save(output_path, 'WEBP', quality=quality)

    print(f"Frame saved to {output_path}")


if __name__ == "__main__":
    input_path = r'C:\Users\meet2\Downloads\pexels_videos_1409899 (2160p).mp4'
    input_path = r'C:\Users\meet2\Downloads\production_id_4763828 (2160p).mp4'
    input_path = r'C:\Users\meet2\Downloads\production_id_5198954 (2160p).mp4'
    output_path = r'C:\Users\meet2\Downloads\preview2.gif'
    output_path = R'C:\Users\meet2\Downloads\preview.webp'

    extract_frame(input_path, output_path)
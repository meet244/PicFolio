import os
from moviepy.editor import VideoFileClip


# code to loop over all files in a directory
def list_files(startpath):
    for i in os.listdir(startpath):
        path = os.path.join(startpath, i)
        if os.path.isfile(path):
            if('.mp4' in path):
                clip = VideoFileClip(path)
                clip.write_gif(path.replace(".mp4",'.gif'),fps=clip.duration)


list_files(r'E:\Picfolio\meet244\preview\2024\2\15')
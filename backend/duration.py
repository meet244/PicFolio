import os
import moviepy.editor as mp
import sqlite3

# connect to database
conn = sqlite3.connect(r'F:\Picfolio\meet244\data.db')
c = conn.cursor()


path = r'F:\Picfolio\meet244\master'

# loop over all files and directories recursively
for root, dirs, files in os.walk(path):
    for file in files:
        if file.endswith('.mp4'):
            # code to calculate duration of video file
            # clip = mp.VideoFileClip(os.path.join(root, file))
            # duration = clip.duration
            # hours = int(duration // 3600)
            # minutes = int((duration % 3600) // 60)
            # seconds = int(duration % 60)
            # seconds = str(seconds).zfill(2)
            file = file[:-4]
            # if hours != 0:
            #     duration = f"{hours}:{minutes}:{seconds}"
            # else:
            #     duration = f"{minutes}:{seconds}"
            # insert duration into database
            c.execute("UPDATE assets SET blurry = ? WHERE id = ?", (0, int(file)))
        os.path.join(root, file)
    for dir in dirs:
        print
        os.path.join(root, dir)

# commit changes
conn.commit()

# close database connection
conn.close()
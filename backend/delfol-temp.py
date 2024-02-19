import os
import shutil

def remove_directory(path):
    try:
        shutil.rmtree(path)
    except:pass

dirs = [
    'preview',
    'temp',
    'master',
    'data/face'
]
try:
    os.remove('data.db')
except:pass
for dir in dirs:
    remove_directory(dir)

for i in os.listdir(r'data\training'):
    try:
        if(int(i) not in [1,2,3,4,5,6,7,8]):
            remove_directory(os.path.join(r"data\training",i))
    except:
        os.remove(os.path.join(r"data\training",i))
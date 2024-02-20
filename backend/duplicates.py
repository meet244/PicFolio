import difPy
import sqlite3
import json

def read_config():
    with open('config.json') as f:
        config = json.load(f)
    print("Config loaded")
    return config

if __name__ == "__main__":

    config = None

    config = read_config()

    for u in config['users']:

        try:
            dif = difPy.build(f"{config['path']}/{u}/master/", in_folder=True, recursive=True, show_progress=False, logs=False)
        except Exception as e:
            print(e)
            continue
        search = difPy.search(dif, 'similar')
        print(search.result)
        print(search.lower_quality)

        output = search.result
        lower = search.lower_quality

        img1 = None
        img2 = None

        connection = sqlite3.connect(f'{config["path"]}/{u}/data.db', check_same_thread=False)
        cursor = connection.cursor()

        for op in output:
            for key, value in output[op]['contents'].items():
                for k,v in (value['matches'].items()):
                    img1 = (value['location'])
                    img2 = (v['location'])
                    print(img1)
                    print(img2)
                    if(img1 in lower['lower_quality']):
                        t = img1
                        img1 = img2
                        img2 = t
                    img1 = img1.split("\\")[-1].split('.')[0]
                    img2 = img2.split("\\")[-1].split('.')[0]
                    print(img1)
                    print(img2)
                    
                    try:
                        cursor.execute("INSERT INTO duplicates (asset_id, asset_id2) VALUES (?, ?)", (img1, img2))
                    except Exception as e:
                        print(e)

        connection.commit()
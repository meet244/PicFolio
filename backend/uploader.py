import os
import requests

#workhere

for i in os.listdir(r"D:\imgs\college\2021-2022\Sat2 pain free trees"):

    if not '.mp4' in i:
        continue

    if '.gif' in i:
        continue

    # Define the URL and payload
    if 'json' in i: 
        continue

    url = "http://127.0.0.1:7251/api/upload"
                                
    payload = {
        "username": "meet244",
        "compress": "True",
    }

    files = {
        "asset": open(fr"D:\imgs\college\2021-2022\Sat2 pain free trees\{i}", "rb")
    }

    # Send the request
    response = requests.post(url, data=payload, files=files)

    # Print the response
    print(response.text)

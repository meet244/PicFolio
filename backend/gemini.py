import os
from dotenv import load_dotenv
import google.generativeai as genai
import threading


load_dotenv()

genai.configure(api_key=os.getenv('Gemini'))

model = genai.GenerativeModel('gemini-pro')

# from "ram_tag_list.txt" file read the tags
tags = None
with open("ram_tag_list.txt", "r") as file:
    tags = file.read()


sent = "beachside, with my girlfriend, i was enjoying the sunset. It was a beautiful evening"
resp = []
def get_tags(sent):
    global resp
    response = model.generate_content(tags+"\n\n\n From above tags, i want you to give me related and proper tags, each separated by comma related to following sentence - \n\n\n"+sent)  
    print("got")
    for i in response.text.split(','):
        resp.append(i.strip())
threads = []
t = threading.Thread(target=get_tags, args=(sent,))
threads.append(t)
t.start()
t = threading.Thread(target=get_tags, args=(sent,))
threads.append(t)
t.start()
t = threading.Thread(target=get_tags, args=(sent,))
threads.append(t)
t.start()

for t in threads:
    t.join()
resp = set(resp)

f = []
for t in resp:
    # print(t)
    for tg in tags.splitlines():
        # if tg in t:
        if tg.lower() == t.lower():
            f.append(tg)

print(f)


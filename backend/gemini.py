import os
from dotenv import load_dotenv
import google.generativeai as genai
import threading


load_dotenv()

genai.configure(api_key=os.getenv('Gemini'))

model = genai.GenerativeModel('gemini-pro')


def get_ai_names(sent):
    try:
        resp = []
        response = model.generate_content("From following sentence give me names that are mentioned, each separated by comma and if there are no names give ''- \n\n\n"+sent)  
        print("got")
        try:
            for i in response.text.split(','):
                resp.append(i.strip())
            return resp
        except:
            resp.append(response.text) 
            return resp
    except Exception as e:
        # print(e)
        return None

def get_ai_tags(sent):
    if not sent:
        return None
    try:
        tags = None
        with open("ram_tag_list.txt", "r") as file:
            tags = file.read()

        resp = []
        def get_tags(sent):
            try:
                response = model.generate_content(tags+"\n\n\n From above tags, i want you to give me related and proper tags, each separated by comma related to following sentence - \n\n\n"+sent)  
                print("got")
                for i in response.text.split(','):
                    resp.append(i.strip())
            except:
                pass

        threads = []
        t = threading.Thread(target=get_tags, args=(sent,))
        threads.append(t)
        t.start()
        t = threading.Thread(target=get_tags, args=(sent,))
        threads.append(t)
        t.start()
        # t = threading.Thread(target=get_tags, args=(sent,))
        # threads.append(t)
        # t.start()

        for t in threads:
            t.join()
        resp = set(resp)

        f = []
        for t in resp:
            for tg in tags.splitlines():
                if tg.lower() == t.lower():
                    f.append(tg)
        return f
    except:
        return None
    
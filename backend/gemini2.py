import os
from dotenv import load_dotenv
import google.generativeai as genai
import threading


load_dotenv()

genai.configure(api_key=os.getenv('Gemini'))

model = genai.GenerativeModel('gemini-pro')


def get_ai_names(sent):
    resp = []
    try:
        response = model.generate_content("From following sentence give me names that are mentioned, each separated by comma - \n\n\n"+sent)  
        print("got")
        if response.status_code == 200:
            try:
                for i in response.text.split(','):
                    resp.append(i.strip())
            except:
                resp.append(response.text)    
        return resp        
    except:
        return None


import os
from dotenv import load_dotenv
import google.generativeai as genai

load_dotenv()

genai.configure(api_key=os.getenv('Gemini'))

model = genai.GenerativeModel('gemini-pro')

response = model.generate_content("hi")

print(response.text)
# print(response.prompt_feedback)
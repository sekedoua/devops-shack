from fastapi import FastAPI


import openai
import os
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()
# Configure OpenAI API Key
openai.api_key = os.getenv("OPENAI_API_KEY")

@app.get("/")
def read_root():
	return {"message": "Welcome to Chatbot API"}

@app.post("/chat/")
def chat_with_bot(user_input: str):
	response = openai.ChatCompletion.create(
	model="gpt-3.5-turbo",
	messages=[{"role": "user", "content": user_input}]
	)
	return {"bot_response": response["choices"][0]["message"]["content"]}

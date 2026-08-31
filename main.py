from fastapi import FastAPI
import time

from fastapi import Request
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

import openai
import os
import os
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

#Metrics Definition
REQUEST_COUNT = Counter(
    "chatbot_http_requests_total",
    "Total number of HTTP requests",
    ["method", "endpoint", "status"],
)

REQUEST_LATENCY = Histogram(
    "chatbot_http_request_duration_seconds",
    "HTTP request duration in seconds",
    ["endpoint"],
)

# Configure OpenAI API Key
openai.api_key = os.getenv("OPENAI_API_KEY")


@app.middleware("http")
async def prometheus_metrics(request: Request, call_next):
    start_time = time.perf_counter()

    response = await call_next(request)

    duration = time.perf_counter() - start_time

    endpoint = request.url.path

    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=endpoint,
        status=str(response.status_code),
    ).inc()

    REQUEST_LATENCY.labels(
        endpoint=endpoint,
    ).observe(duration)

    return response


@app.get("/")
def read_root():
	return {"message": "Welcome to Chatbot API"}

@app.get("/health")
def health():
    return {"status": "ok"}

@app.get("/ready")
def ready():
    return {"status": "ready"}

@app.get("/metrics")
def metrics():
    return Response(
        content=generate_latest(),
        media_type=CONTENT_TYPE_LATEST,
    )

@app.post("/chat/")
def chat_with_bot(user_input: str):
	response = openai.ChatCompletion.create(
	model="gpt-3.5-turbo",
	messages=[{"role": "user", "content": user_input}]
	)
	return {"bot_response": response["choices"][0]["message"]["content"]}

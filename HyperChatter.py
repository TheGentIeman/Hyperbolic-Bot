import time
import requests
import logging

API_ENDPOINT = "https://api.hyperbolic.xyz/v1/chat/completions"
API_KEY = "$API_KEY" 
MODEL_NAME = "NousResearch/Hermes-3-Llama-3.1-70B"  
TOKEN_LIMIT = 2048
TEMP = 0.7
TOP_PROB = 0.9
PAUSE_DURATION = 25  

logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("HyperbolicChat")

def fetch_ai_response(prompt: str) -> str:
    """Отправляет запрос к API и возвращает ответ"""
    payload = {
        "messages": [{"role": "user", "content": prompt}],
        "model": MODEL_NAME,
        "max_tokens": TOKEN_LIMIT,
        "temperature": TEMP,
        "top_p": TOP_PROB
    }
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    try:
        resp = requests.post(API_ENDPOINT, headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        return resp.json().get("choices", [{}])[0].get("message", {}).get("content", "No response received")
    except requests.RequestException as err:
        logger.error(f"Ошибка запроса: {err}")
        return "Error fetching response"

def load_questions(file_path: str) -> list:
    """Загружает вопросы из файла"""
    try:
        with open(file_path, encoding="utf-8") as file:
            return [line.strip() for line in file if line.strip()]
    except FileNotFoundError:
        logger.error("Файл с вопросами не найден.")
    except Exception as err:
        logger.error(f"Ошибка чтения файла: {err}")
    return []

def cycle_through_questions():
    """Циклически задает вопросы из файла и получает ответы"""
    questions = load_questions("questions.txt")
    if not questions:
        return
    
    idx = 0
    while True:
        logger.info(f"Вопрос [{idx + 1}/{len(questions)}]: {questions[idx]}")
        response = fetch_ai_response(questions[idx])
        logger.info(f"Ответ: {response}")
        idx = (idx + 1) % len(questions)
        time.sleep(PAUSE_DURATION)

if __name__ == "__main__":
    cycle_through_questions()

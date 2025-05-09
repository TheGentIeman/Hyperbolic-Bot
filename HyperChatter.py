import time
import requests
import logging
import os

# --- Конфигурация API ---
API_ENDPOINT = "https://api.hyperbolic.xyz/v1/chat/completions"
API_KEY = os.environ.get("API_KEY")  # Надежный способ подгрузить ключ
MODEL_NAME = "NousResearch/Hermes-3-Llama-3.1-70B"
TOKEN_LIMIT = 2048
TEMP = 0.7
TOP_PROB = 0.9
PAUSE_DURATION = 25  # Секунд между запросами

# --- Логирование ---
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("HyperbolicBot")

def fetch_ai_response(prompt: str) -> str:
    """Отправляет запрос в Hyperbolic API и возвращает текст ответа"""
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "messages": [{"role": "user", "content": prompt}],
        "model": MODEL_NAME,
        "max_tokens": TOKEN_LIMIT,
        "temperature": TEMP,
        "top_p": TOP_PROB
    }

    try:
        response = requests.post(API_ENDPOINT, headers=headers, json=payload, timeout=30)
        response.raise_for_status()
        data = response.json()
        content = (
            data.get("choices", [{}])[0]
            .get("message", {})
            .get("content")
        )
        return content if content else "Нет ответа от модели"
    except Exception as e:
        logger.error(f"Ошибка при запросе: {e}")
        return "Ошибка получения ответа"

def load_questions(filename="questions.txt") -> list:
    """Загружает список вопросов из файла"""
    try:
        filepath = os.path.join(os.getcwd(), filename)
        with open(filepath, encoding="utf-8") as f:
            questions = [line.strip() for line in f if line.strip()]
            if not questions:
                logger.warning("Файл пустой.")
            return questions
    except Exception as e:
        logger.error(f"Ошибка при загрузке вопросов: {e}")
        return []

def run():
    """Циклически отправляет вопросы и выводит ответы"""
    questions = load_questions()
    if not questions:
        logger.error("Нет доступных вопросов. Завершение.")
        return

    index = 0
    while True:
        question = questions[index]
        logger.info(f"Вопрос #{index+1}: {question}")
        answer = fetch_ai_response(question)
        logger.info(f"Ответ: {answer}")
        index = (index + 1) % len(questions)
        time.sleep(PAUSE_DURATION)

if __name__ == "__main__":
    if not API_KEY:
        logger.error("API-ключ не установлен. Установите переменную окружения API_KEY.")
    else:
        run()

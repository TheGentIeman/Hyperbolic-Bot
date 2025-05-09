#!/bin/bash

# Проверка необходимых утилит
if ! command -v figlet &> /dev/null; then
    echo "figlet не найден. Устанавливаем..."
    sudo apt update && sudo apt install -y figlet
fi

if ! command -v whiptail &> /dev/null; then
    echo "whiptail не найден. Устанавливаем..."
    sudo apt update && sudo apt install -y whiptail
fi

# Цвета
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
PINK="\e[35m"
NC="\e[0m"

# Приветствие
echo -e "${PINK}$(figlet -w 150 -f standard "Soft by The Gentleman")${NC}"
echo "==============================================================================================================================="
echo "Добро пожаловать! Начинаем установку необходимых библиотек, пока подпишись на мой канал для обновлений и поддержки:"
echo ""
echo "The Gentleman - https://t.me/GentleChron"
echo "==============================================================================================================================="

# Анимация загрузки
animate_loading() {
    for ((i = 1; i <= 5; i++)); do
        printf "\r${GREEN}Подгружаем меню${NC}."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}.."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}..."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}   "
        sleep 0.3
    done
    echo ""
}

animate_loading

# Меню
CHOICE=$(whiptail --title "Меню HyperChatter" \
    --menu "Выберите действие:" 15 50 5 \
    "1" "Установить бота" \
    "2" "Просмотр логов" \
    "3" "Перезапустить бота" \
    "4" "Ввести свои вопросы" \
    "5" "Удалить бота" \
    3>&1 1>&2 2>&3)

# Пути и ссылки
PROJECT_DIR="$HOME/hyperbolic"
BOT_FILE="HyperChatter.py"
QUESTIONS_FILE="$PROJECT_DIR/questions.txt"
BOT_URL="https://raw.githubusercontent.com/TheGentIeman/Hyperbolic-Bot/main/$BOT_FILE"
QUESTIONS_URL="https://raw.githubusercontent.com/TheGentIeman/Hyperbolic-Bot/main/Questions.txt"
SERVICE_NAME="hyper-bot.service"
USERNAME=$(whoami)
HOME_DIR=$(eval echo ~$USERNAME)

case $CHOICE in
    1)
        echo -e "${BLUE}Установка зависимостей...${NC}"
        sudo apt update && sudo apt upgrade -y
        sudo apt install -y python3 python3-venv python3-pip curl

        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR" || exit 1

        echo -e "${BLUE}Создание виртуального окружения...${NC}"
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip requests
        deactivate
        cd

        echo -e "${BLUE}Загрузка кода бота...${NC}"
        curl -fsSL -o "$PROJECT_DIR/$BOT_FILE" "$BOT_URL"

        echo -e "${BLUE}Загрузка вопросов...${NC}"
        curl -fsSL -o "$QUESTIONS_FILE" "$QUESTIONS_URL"

        echo -e "${YELLOW}Введите ваш API-ключ для Hyperbolic:${NC}"
        read -r USER_API_KEY

        sed -i "s/API_KEY = \"\$API_KEY\"/API_KEY = \"$USER_API_KEY\"/" "$PROJECT_DIR/$BOT_FILE"

        echo -e "${BLUE}Создание systemd-сервиса...${NC}"
        sudo bash -c "cat <<EOT > /etc/systemd/system/$SERVICE_NAME
[Unit]
Description=HyperChatter Bot
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/venv/bin/python $PROJECT_DIR/$BOT_FILE
Restart=always
Environment=PATH=$PROJECT_DIR/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

[Install]
WantedBy=multi-user.target
EOT"

        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        sudo systemctl start $SERVICE_NAME

        echo -e "${GREEN}✅ Бот установлен и запущен.${NC}"
        echo -e "${YELLOW}Логи (Ctrl+C для выхода):${NC}"
        sleep 2
        sudo journalctl -u $SERVICE_NAME -f
        ;;

    2)
        echo -e "${BLUE}Открытие логов...${NC}"
        sudo journalctl -u $SERVICE_NAME -f
        ;;

    3)
        echo -e "${BLUE}Перезапуск бота...${NC}"
        sudo systemctl restart $SERVICE_NAME
        sudo journalctl -u $SERVICE_NAME -f
        ;;

    4)
        echo -e "${BLUE}Ввод собственных вопросов...${NC}"
        sudo systemctl stop $SERVICE_NAME
        > "$QUESTIONS_FILE"
        echo -e "${YELLOW}Введите вопросы (один на строку). Завершите Ctrl+D:${NC}"
        cat > "$QUESTIONS_FILE"
        sudo systemctl restart $SERVICE_NAME
        sudo journalctl -u $SERVICE_NAME -f
        ;;

    5)
        echo -e "${RED}Удаление бота...${NC}"
        sudo systemctl stop $SERVICE_NAME
        sudo systemctl disable $SERVICE_NAME
        sudo rm "/etc/systemd/system/$SERVICE_NAME"
        sudo systemctl daemon-reload
        rm -rf "$PROJECT_DIR"
        echo -e "${GREEN}Бот и его файлы удалены.${NC}"
        ;;

    *)
        echo -e "${RED}Неверный выбор. Завершение.${NC}"
        ;;
esac

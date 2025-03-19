#!/bin/bash

# Проверка наличия необходимых утилит, установка если отсутствует
if ! command -v figlet &> /dev/null; then
    echo "figlet не найден. Устанавливаем..."
    sudo apt update && sudo apt install -y figlet
fi

if ! command -v whiptail &> /dev/null; then
    echo "whiptail не найден. Устанавливаем..."
    sudo apt update && sudo apt install -y whiptail
fi

# Определяем цвета
YELLOW="\e[33m"
CYAN="\e[36m"
BLUE="\e[34m"
GREEN="\e[32m"
RED="\e[31m"
PINK="\e[35m"
NC="\e[0m"

# Вывод приветственного текста
echo -e "${PINK}$(figlet -w 150 -f standard "Softs by The Gentleman")${NC}"

echo "================================================================="
echo "Добро пожаловать! Подпишись на мой Telegram-канал: https://t.me/GentleChron"
echo "================================================================="
echo ""

# Функция анимации
animate_loading() {
    for ((i = 1; i <= 5; i++)); do
        printf "\r${GREEN}Подгружаем меню${NC}."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}.."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}..."
        sleep 0.3
        printf "\r${GREEN}Подгружаем меню${NC}"
        sleep 0.3
    done
    echo ""
}

animate_loading
echo ""

# Вывод меню
CHOICE=$(whiptail --title "Меню действий" \
    --menu "Выберите действие:" 15 50 5 \
    "1" "Установить бота" \
    "2" "Обновить бота" \
    "3" "Проверка работы бота" \
    "4" "Перезапустить бота" \
    "5" "Удаленить бота" \
    3>&1 1>&2 2>&3)

case $CHOICE in
    1)
        echo -e "${BLUE}Установка бота...${NC}"

        sudo apt update && sudo apt upgrade -y
        sudo apt install -y python3 python3-venv python3-pip curl

        PROJECT_DIR="$HOME/hyperbolic"
        mkdir -p "$PROJECT_DIR"
        cd "$PROJECT_DIR" || exit 1

        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install requests
        deactivate
        cd

        # Скачивание бота
        BOT_URL="https://raw.githubusercontent.com/TheGentIeman/Hyperbolic-Bot/main/HyperChatter.py"
        curl -fsSL -o "$PROJECT_DIR/HyperChatter.py" "$BOT_URL"

        # Запрос API-ключа
        echo -e "${YELLOW}Введите ваш API-ключ для Hyperbolic:${NC}"
        read -r USER_API_KEY
        sed -i "s/API_KEY = \"\$API_KEY\"/API_KEY = \"$USER_API_KEY\"/" "$PROJECT_DIR/HyperChatter.py"

        # Скачивание вопросов
        QUESTIONS_URL="https://raw.githubusercontent.com/TheGentIeman/Hyperbolic-Bot/main/Questions.txt"
        curl -fsSL -o "$PROJECT_DIR/questions.txt" "$QUESTIONS_URL"

        USERNAME=$(whoami)
        HOME_DIR=$(eval echo ~$USERNAME)

        sudo bash -c "cat <<EOT > /etc/systemd/system/hyper-bot.service
[Unit]
Description=Hyperbolic API Bot Service
After=network.target

[Service]
User=$USERNAME
WorkingDirectory=$HOME_DIR/hyperbolic
ExecStart=$HOME_DIR/hyperbolic/venv/bin/python $HOME_DIR/hyperbolic/HyperChatter.py
Restart=always
Environment=PATH=$HOME_DIR/hyperbolic/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin

[Install]
WantedBy=multi-user.target
EOT"

        sudo systemctl daemon-reload
        sudo systemctl restart systemd-journald
        sudo systemctl enable hyper-bot.service
        sudo systemctl start hyper-bot.service

        echo -e "${YELLOW}Команда для проверки логов:${NC}"
        echo "sudo journalctl -u hyper-bot.service -f"
        sleep 2
        sudo journalctl -u hyper-bot.service -f
        ;;

    2)
        echo -e "${BLUE}Обновление бота...${NC}"
        sleep 2
        echo -e "${GREEN}Обновление бота пока не требуется!${NC}"
        ;;

    3)
        echo -e "${BLUE}Просмотр логов...${NC}"
        sudo journalctl -u hyper-bot.service -f
        ;;

    4)
        echo -e "${BLUE}Рестарт бота...${NC}"
        sudo systemctl restart hyper-bot.service
        sudo journalctl -u hyper-bot.service -f
        ;;
        
    5)
        echo -e "${BLUE}Удаление бота...${NC}"

        sudo systemctl stop hyper-bot.service
        sudo systemctl disable hyper-bot.service
        sudo rm /etc/systemd/system/hyper-bot.service
        sudo systemctl daemon-reload
        sleep 2

        rm -rf "$HOME_DIR/hyperbolic"

        echo -e "${GREEN}Бот успешно удален!${NC}"
        sleep 1
        ;;
    
    *)
        echo -e "${RED}Неверный выбор. Завершение программы.${NC}"
        ;;
esac

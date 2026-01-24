#!/bin/bash

# ==========================================
#  VIBRANT DASHBOARD UI
# ==========================================

# --- Colors ---
ESC=$(printf '\033')
RESET="${ESC}[0m"
BOLD="${ESC}[1m"

# Palette
RED="${ESC}[38;5;196m"
GREEN="${ESC}[38;5;46m"
YELLOW="${ESC}[38;5;226m"
BLUE="${ESC}[38;5;39m"
PURPLE="${ESC}[38;5;201m"
CYAN="${ESC}[38;5;51m"
ORANGE="${ESC}[38;5;208m"
WHITE="${ESC}[97m"

# Backgrounds
BG_BLUE="${ESC}[44m"
BG_PURPLE="${ESC}[45m"

# --- Configuration ---
CONTAINER="xrdp-server"
IMAGE="danielguerra/ubuntu-xrdp"

# --- Helper Functions ---

get_system_info() {
    # Check Public IP
    PUBLIC_IP=$(curl -s --max-time 2 ifconfig.me)
    if [ -z "$PUBLIC_IP" ]; then
        PUBLIC_IP="${RED}Offline${RESET}"
    else
        PUBLIC_IP="${CYAN}$PUBLIC_IP${RESET}"
    fi
    
    # Check Local IP
    LOCAL_IP=$(hostname -I | awk '{print $1}')
    LOCAL_IP="${BLUE}$LOCAL_IP${RESET}"
}

check_status() {
    # Check Container
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
        STATUS_ICON="${GREEN}●${RESET}"
        STATUS_TEXT="${GREEN}ONLINE${RESET}"
    else
        STATUS_ICON="${RED}●${RESET}"
        STATUS_TEXT="${RED}OFFLINE${RESET}"
    fi

    # Check Docker
    if command -v docker &>/dev/null; then
        DOCKER_STATUS="${GREEN}✔ Installed${RESET}"
    else
        DOCKER_STATUS="${RED}✘ Missing${RESET}"
    fi
}

# --- Action Functions ---

install_xrdp() {
    echo -e "\n${CYAN}  🚀 Starting Installation...${RESET}"
    
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}  -> Installing Docker Engine...${RESET}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker --now
    fi

    echo -e "${BLUE}  -> Setting up Container...${RESET}"
    docker rm -f $CONTAINER 2>/dev/null
    docker run -d --name $CONTAINER -p 3389:3389 --privileged --restart unless-stopped $IMAGE > /dev/null

    echo -e "${GREEN}  ✨ Installation Complete!${RESET}"
    read -p "  Press Enter..."
}

uninstall_xrdp() {
    echo -e "\n${RED}  🗑 Removing Server...${RESET}"
    docker rm -f $CONTAINER 2>/dev/null
    echo -e "${GREEN}  ✔ Done.${RESET}"
    read -p "  Press Enter..."
}

show_creds() {
    echo -e "\n${PURPLE}  🔐 LOGIN DETAILS${RESET}"
    echo -e "  -------------------------"
    echo -e "  User : ${YELLOW}ubuntu${RESET}"
    echo -e "  Pass : ${YELLOW}ubuntu${RESET}"
    echo -e "  Port : ${ORANGE}3389${RESET}"
    read -p "  Press Enter..."
}

# --- Menu Display ---

show_menu() {
    clear
    get_system_info
    check_status
    
    # Colorful Header
    echo -e "${BG_BLUE}${WHITE}${BOLD}      🌈  ULTIMATE XRDP MANAGER      ${RESET}"
    echo -e "${BLUE}  ───────────────────────────────────${RESET}"
    
    # Status Section
    echo -e "  ${BOLD}STATUS MONITOR${RESET}"
    echo -e "  Docker Engine : $DOCKER_STATUS"
    echo -e "  XRDP Server   : $STATUS_ICON $STATUS_TEXT"
    echo -e "  Public IP     : $PUBLIC_IP"
    echo -e "  Local IP      : $LOCAL_IP"
    echo -e "${BLUE}  ───────────────────────────────────${RESET}"

    # Menu Options (Rainbow)
    echo -e "  ${BOLD}MENU${RESET}"
    echo -e "  ${CYAN}[1]${RESET}  Install Server     ${CYAN}⚡${RESET}"
    echo -e "  ${RED}[2]${RESET}  Uninstall Server   ${RED}🗑${RESET}"
    echo -e "  ${YELLOW}[3]${RESET}  View Password      ${YELLOW}🔑${RESET}"
    echo -e "  ${PURPLE}[4]${RESET}  Refresh Page       ${PURPLE}🔄${RESET}"
    echo -e "  ${ORANGE}[0]${RESET}  Exit Tool          ${ORANGE}❌${RESET}"
    echo ""
    echo -e -n "  ${GREEN}➤ Choose Option:${RESET} "
}

# --- Main Loop ---

while true; do
    show_menu
    read -n 1 opt
    case $opt in
        1) install_xrdp ;;
        2) uninstall_xrdp ;;
        3) show_creds ;;
        4) ;; 
        0) echo -e "\n${ORANGE}  Bye!${RESET}"; exit 0 ;;
        *) ;;
    esac
done

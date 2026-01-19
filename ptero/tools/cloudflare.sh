#!/bin/bash

# ==================================================
#  CLOUDFLARED TUNNEL MANAGER | DASHBOARD UI
# ==================================================

# --- COLORS & STYLES ---
C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_PURPLE='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'

# --- UI DRAWING FUNCTIONS ---

draw_header() {
    clear
    local date_time=$(date '+%Y-%m-%d %H:%M')
    
    # Check Status
    local status="${C_GRAY}NOT INSTALLED${C_RESET}"
    local pid_info=""
    
    if command -v cloudflared &>/dev/null; then
        if systemctl is-active --quiet cloudflared; then
            status="${C_GREEN}● RUNNING${C_RESET}"
            pid_info="(PID: $(pgrep -x cloudflared))"
        else
            status="${C_RED}● STOPPED${C_RESET}"
        fi
    fi

    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}${C_PURPLE}☁️  CLOUDFLARE TUNNEL MANAGER v2.0${C_RESET}                                  ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}TIME:${C_RESET} ${C_WHITE}$date_time${C_RESET}                                             ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_CYAN}SERVICE STATUS:${C_RESET} $status $pid_info                 ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO")    echo -e " ${C_BLUE}➜${C_RESET} ${C_WHITE}$message${C_RESET}" ;;
        "WARN")    echo -e " ${C_YELLOW}⚠${C_RESET} ${C_YELLOW}$message${C_RESET}" ;;
        "ERROR")   echo -e " ${C_RED}✖${C_RESET} ${C_RED}$message${C_RESET}" ;;
        "SUCCESS") echo -e " ${C_GREEN}✔${C_RESET} ${C_GREEN}$message${C_RESET}" ;;
        "INPUT")   echo -ne " ${C_PURPLE}➤${C_RESET} ${C_CYAN}$message${C_RESET}" ;;
    esac
}

# --- ACTIONS ---

install_cloudflared() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "INFO" "Preparing Environment..."

    # 1. Add Repo
    print_status "INFO" "Adding Cloudflare GPG Key & Repo..."
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list >/dev/null

    # 2. Install
    print_status "INFO" "Installing Package (apt update)..."
    sudo apt-get update -qq >/dev/null
    sudo apt-get install -y cloudflared -qq >/dev/null 2>&1

    if ! command -v cloudflared >/dev/null; then
        print_status "ERROR" "Installation Failed."
        read -p "Press Enter..."
        return
    fi
    print_status "SUCCESS" "Binary Installed."

    # 3. Clean Old Service
    if systemctl list-units --type=service | grep -q cloudflared; then
        print_status "WARN" "Old service detected. Cleaning..."
        sudo cloudflared service uninstall >/dev/null 2>&1
    fi

    # 4. Input Token (User Proof Logic)
    echo ""
    echo -e "${C_YELLOW}╔══════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_YELLOW}║  INPUT REQUIRED                                  ║${C_RESET}"
    echo -e "${C_YELLOW}║  Paste your Tunnel Token below.                  ║${C_RESET}"
    echo -e "${C_YELLOW}║  (You can paste the whole 'sudo...' command)     ║${C_RESET}"
    echo -e "${C_YELLOW}╚══════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    read -rp " ➤ Token: " USER_INPUT

    # Logic to strip the command and keep only the token
    CF_TOKEN=$(echo "$USER_INPUT" | sed 's/sudo cloudflared service install //g' | sed 's/cloudflared service install //g' | xargs)

    if [[ -z "$CF_TOKEN" ]]; then
        print_status "ERROR" "Token is empty."
        read -p "Press Enter..."
        return
    fi

    # 5. Install Service
    print_status "INFO" "Registering Service..."
    sudo cloudflared service install "$CF_TOKEN"
    
    # 6. Verify
    sleep 2
    if systemctl is-active --quiet cloudflared; then
        print_status "SUCCESS" "Tunnel is Active & Running!"
        
    else
        print_status "ERROR" "Service installed but failed to start."
        echo -e "   Check logs: sudo journalctl -u cloudflared -f"
    fi
    
    read -p "Press Enter to return..."
}

uninstall_cloudflared() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_RED}⚠️  DANGER ZONE: UNINSTALL${C_RESET}"
    
    read -p "$(print_status "INPUT" "Remove Cloudflared Completely? (y/N): ")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then return; fi

    print_status "INFO" "Stopping Service..."
    sudo cloudflared service uninstall >/dev/null 2>&1
    
    print_status "INFO" "Removing Package..."
    sudo apt-get remove -y cloudflared -qq >/dev/null 2>&1
    
    print_status "INFO" "Cleaning Repos & Keys..."
    sudo rm -f /etc/apt/sources.list.d/cloudflared.list
    sudo rm -f /usr/share/keyrings/cloudflare-main.gpg
    
    print_status "SUCCESS" "Uninstallation Complete."
    read -p "Press Enter..."
}

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "${C_WHITE} AVAILABLE ACTIONS:${C_RESET}"
    echo -e " ${C_GREEN}[1]${C_RESET} Install / Update Tunnel"
    echo -e " ${C_RED}[2]${C_RESET} Uninstall Completely"
    echo -e " ${C_GRAY}[0]${C_RESET} Exit"
    echo ""
    
    read -p "$(print_status "INPUT" "Select Option: ")" option
    
    case $option in
        1) install_cloudflared ;;
        2) uninstall_cloudflared ;;
        0) echo -e "\n${C_PURPLE}👋 Exiting...${C_RESET}"; exit 0 ;;
        *) print_status "ERROR" "Invalid Option."; sleep 1 ;;
    esac
done

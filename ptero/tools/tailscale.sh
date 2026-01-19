#!/bin/bash

# ==================================================
#  TAILSCALE NETWORK MANAGER | v2.1 (Fixed)
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

# --- HELPER: SAFE HOSTNAME ---
get_hostname() {
    if command -v hostname &> /dev/null; then
        hostname
    elif [ -f /etc/hostname ]; then
        head -n 1 /etc/hostname
    elif [ -n "$HOSTNAME" ]; then
        echo "$HOSTNAME"
    else
        echo "Localhost"
    fi
}

# --- UI DRAWING FUNCTIONS ---

draw_header() {
    clear
    # Get System Data safely
    local host_name=$(get_hostname)
    local date_time=$(date '+%Y-%m-%d %H:%M')
    
    # Get Tailscale Status
    local ts_status="${C_RED}OFFLINE${C_RESET}"
    local ts_ip="${C_GRAY}Unknown${C_RESET}"
    
    # Check if tailscale is installed
    if command -v tailscale &>/dev/null; then
        # Check if service is running (supports systemd and openrc/generic)
        if pgrep -x "tailscaled" > /dev/null; then
            ts_status="${C_GREEN}ACTIVE${C_RESET}"
            
            # Try to grab the IP
            local ip_check=$(tailscale ip -4 2>/dev/null)
            if [[ -n "$ip_check" ]]; then
                ts_ip="${C_CYAN}$ip_check${C_RESET}"
            else
                ts_ip="${C_YELLOW}Auth Required${C_RESET}"
            fi
        else
            ts_status="${C_YELLOW}STOPPED${C_RESET}"
        fi
    else
        ts_status="${C_GRAY}NOT INSTALLED${C_RESET}"
    fi

    echo -e "${C_BLUE}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_WHITE}${C_PURPLE}🛡️  TAILSCALE NETWORK MANAGER v2.1${C_RESET}                                  ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}HOST:${C_RESET} ${C_WHITE}$host_name${C_RESET}   ${C_GRAY}TIME:${C_RESET} ${C_WHITE}$date_time${C_RESET}                                ${C_BLUE}║${C_RESET}"
    echo -e "${C_BLUE}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BLUE}║${C_RESET} ${C_CYAN}SERVICE STATUS:${C_RESET} $ts_status        ${C_CYAN}TAILSCALE IP:${C_RESET} $ts_ip       ${C_BLUE}║${C_RESET}"
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

install_tailscale() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "INFO" "Initializing Installation Sequence..."
    
    # 1. Download
    print_status "INFO" "Downloading Official Installer..."
    if ! command -v curl &> /dev/null; then
        print_status "ERROR" "'curl' is required but not found."
        read -p "Press Enter..."
        return 1
    fi

    if curl -fsSL https://tailscale.com/install.sh | sh; then
        print_status "SUCCESS" "Core Binaries Installed."
    else
        print_status "ERROR" "Download/Install Failed."
        read -p "Press Enter..."
        return 1
    fi
    
    # 2. Enable Service
    print_status "INFO" "Enabling System Daemon..."
    if command -v systemctl &> /dev/null; then
        sudo systemctl enable --now tailscaled
    elif command -v service &> /dev/null; then
        sudo service tailscaled start
    else
        # Fallback for minimal containers
        sudo tailscaled > /dev/null 2>&1 &
    fi
    
    print_status "SUCCESS" "Service Active."
    
    # 3. Authenticate
    echo ""
    echo -e "${C_YELLOW}╔══════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_YELLOW}║  AUTHENTICATION REQUIRED                         ║${C_RESET}"
    echo -e "${C_YELLOW}║  Please click the link below to verify device    ║${C_RESET}"
    echo -e "${C_YELLOW}╚══════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    sudo tailscale up
    
    echo ""
    print_status "SUCCESS" "Installation & Setup Complete!"
    read -p "Press Enter to return to dashboard..."
}

uninstall_tailscale() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo -e "${C_RED}⚠️  DANGER ZONE: UNINSTALL${C_RESET}"
    echo -e "This will remove the Tailscale package and delete all configs."
    echo ""
    
    read -p "$(print_status "INPUT" "Are you sure? (y/N): ")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_status "INFO" "Cancelled."
        return
    fi
    
    print_status "INFO" "Stopping Service..."
    if command -v systemctl &> /dev/null; then
        sudo systemctl stop tailscaled 2>/dev/null
        sudo systemctl disable tailscaled 2>/dev/null
    else
        pkill tailscaled
    fi
    
    print_status "INFO" "Removing Packages..."
    if [ -x "$(command -v apt)" ]; then
        sudo apt purge tailscale -y
        sudo apt autoremove -y
    elif [ -x "$(command -v dnf)" ]; then
        sudo dnf remove tailscale -y
    elif [ -x "$(command -v yum)" ]; then
        sudo yum remove tailscale -y
    elif [ -x "$(command -v apk)" ]; then
        sudo apk del tailscale
    fi
    
    print_status "INFO" "Cleaning Configs..."
    sudo rm -rf /var/lib/tailscale /etc/tailscale /var/cache/tailscale
    
    print_status "SUCCESS" "Tailscale has been removed."
    read -p "Press Enter..."
}

troubleshoot_tailscale() {
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    print_status "INFO" "Running Diagnostics..."
    echo ""
    echo -e "${C_WHITE}1. Service Process:${C_RESET}"
    if pgrep -x "tailscaled" > /dev/null; then
        echo -e "${C_GREEN}Running (PID: $(pgrep -x tailscaled))${C_RESET}"
    else
        echo -e "${C_RED}Not Running${C_RESET}"
    fi
    
    echo ""
    echo -e "${C_WHITE}2. Network Status:${C_RESET}"
    if command -v tailscale &> /dev/null; then
        tailscale status
    else
        echo "Command not found."
    fi
    
    echo ""
    echo -e "${C_WHITE}3. Local IP:${C_RESET}"
    if command -v tailscale &> /dev/null; then
        tailscale ip -4
    fi
    echo ""
    read -p "Press Enter to return..."
}

# --- MAIN LOOP ---

while true; do
    draw_header
    
    echo -e "${C_WHITE} AVAILABLE ACTIONS:${C_RESET}"
    echo -e " ${C_GREEN}[1]${C_RESET} Install Tailscale      ${C_PURPLE}[3]${C_RESET} Troubleshoot / Logs"
    echo -e " ${C_RED}[2]${C_RESET} Uninstall Tailscale    ${C_GRAY}[0]${C_RESET} Exit"
    echo ""
    
    read -p "$(print_status "INPUT" "Select Option: ")" option
    
    case $option in
        1) install_tailscale ;;
        2) uninstall_tailscale ;;
        3) troubleshoot_tailscale ;;
        0) 
            echo -e "\n${C_PURPLE}👋 Exiting...${C_RESET}"
            exit 0 
            ;;
        *) 
            print_status "ERROR" "Invalid Option." 
            sleep 1
            ;;
    esac
done

#!/bin/bash
set -e

# ==================================================
#  WINGS CONFIGURATOR | Nobita-Hosting Edition
# ==================================================

# --- COLORS & STYLES ---
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'
C_BG_BLUE='\033[44m'

# --- UI HELPERS ---

header() {
    clear
    echo -e "${C_BLUE}"
    cat << "EOF"
    ██╗    ██╗██╗███╗   ██╗ ██████╗ ███████╗
    ██║    ██║██║████╗  ██║██╔════╝ ██╔════╝
    ██║ █╗ ██║██║██╔██╗ ██║██║  ███╗███████╗
    ██║███╗██║██║██║╚██╗██║██║   ██║╚════██║
    ╚███╔███╔╝██║██║ ╚████║╚██████╔╝███████║
     ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚══════╝
EOF
    echo -e "${C_RESET}"
    echo -e "   ${C_GRAY}:: AUTO-CONFIGURATION UTILITY ::${C_RESET}"
    echo -e "   ${C_GRAY}:: NOBITA-HOSTING SOLUTIONS   ::${C_RESET}"
    echo ""
    echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
    echo ""
}

print_step() {
    echo -e "${C_BLUE}${C_BOLD}➜ STEP $1:${C_RESET} ${C_WHITE}$2${C_RESET}"
}

print_task() {
    echo -ne "  ${C_GRAY}• $1...${C_RESET}"
}

print_status() {
    local status="$1" # OK or FAIL
    if [ "$status" == "OK" ]; then
        echo -e "\r\033[50C[ ${C_GREEN}OK${C_RESET} ]"
    else
        echo -e "\r\033[50C[${C_RED}FAIL${C_RESET}]"
    fi
}

get_input() {
    # $1 = Prompt text, $2 = Variable name
    echo -ne "  ${C_CYAN}?${C_RESET} $1: "
}

# --- START SCRIPT ---

header

print_step "1/4" "Identity Configuration"
echo -e "  ${C_GRAY}Enter the node credentials from your panel.${C_RESET}"
echo -e "  ${C_GRAY}(Type 'back' at any prompt to return to the previous step)${C_RESET}"
echo ""

# --- INPUT LOGIC (Your logic, wrapped in new UI) ---

# 1. UUID
while true; do
    get_input "Node UUID"
    read UUID
    
    if [ "$UUID" = "back" ]; then
        echo -e "  ${C_YELLOW}⚠ Cannot go back from the first step.${C_RESET}"
        continue
    elif [ -z "$UUID" ]; then
        echo -e "  ${C_RED}✖ UUID cannot be empty.${C_RESET}"
        continue
    else
        break
    fi
done

# 2. Token ID
while true; do
    get_input "Token ID"
    read TOKEN_ID
    
    if [ "$TOKEN_ID" = "back" ]; then
        echo -e "  ${C_YELLOW}↩ Going back to UUID...${C_RESET}"
        # Recurse logic for UUID
        while true; do
             get_input "Node UUID [$UUID]"
             read NEW_UUID
             if [ -n "$NEW_UUID" ]; then UUID="$NEW_UUID"; fi
             break
        done
        continue
    elif [ -z "$TOKEN_ID" ]; then
        echo -e "  ${C_RED}✖ Token ID cannot be empty.${C_RESET}"
        continue
    else
        break
    fi
done

# 3. Token
while true; do
    get_input "Token Secret"
    read TOKEN
    
    if [ "$TOKEN" = "back" ]; then
         echo -e "  ${C_YELLOW}↩ Going back to Token ID...${C_RESET}"
         # Recurse logic for Token ID
         while true; do
            get_input "Token ID [$TOKEN_ID]"
            read NEW_TOKEN_ID
            if [ -n "$NEW_TOKEN_ID" ]; then TOKEN_ID="$NEW_TOKEN_ID"; fi
            break
         done
         continue
    elif [ -z "$TOKEN" ]; then
        echo -e "  ${C_RED}✖ Token cannot be empty.${C_RESET}"
        continue
    else
        break
    fi
done

# 4. Remote URL
while true; do
    get_input "Panel URL (https://panel.example.com)"
    read REMOTE
    
    if [ "$REMOTE" = "back" ]; then
        echo -e "  ${C_YELLOW}↩ Going back to Token Secret...${C_RESET}"
        # Recurse logic for Token
        while true; do
             get_input "Token Secret"
             read NEW_TOKEN
             if [ -n "$NEW_TOKEN" ]; then TOKEN="$NEW_TOKEN"; fi
             break
        done
        continue
    elif [ -z "$REMOTE" ]; then
        echo -e "  ${C_YELLOW}⚠ Using default: https://panel.example.com${C_RESET}"
        REMOTE="https://panel.example.com"
        break
    elif [[ ! "$REMOTE" =~ ^https?:// ]]; then
        echo -e "  ${C_RED}✖ Invalid URL. Must start with http:// or https://${C_RESET}"
        continue
    else
        break
    fi
done

# --- CONFIRMATION CARD ---
echo ""
echo -e "${C_BLUE}╔══════════════════════════════════════════════════╗${C_RESET}"
echo -e "${C_BLUE}║${C_RESET} ${C_BOLD}${C_WHITE}           CONFIGURATION REVIEW           ${C_RESET} ${C_BLUE}║${C_RESET}"
echo -e "${C_BLUE}╠══════════════════════════════════════════════════╣${C_RESET}"
echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}UUID     :${C_RESET} ${C_WHITE}$UUID${C_RESET}"
echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}Token ID :${C_RESET} ${C_WHITE}$TOKEN_ID${C_RESET}"
echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}Token    :${C_RESET} ${C_WHITE}****************${C_RESET}"
echo -e "${C_BLUE}║${C_RESET} ${C_GRAY}Remote   :${C_RESET} ${C_WHITE}$REMOTE${C_RESET}"
echo -e "${C_BLUE}╚══════════════════════════════════════════════════╝${C_RESET}"
echo ""

# Simple Confirm
read -p "$(echo -e "${C_YELLOW}⚠ Proceed with these settings? [Y/n]: ${C_RESET}")" CONFIRM
if [[ "$CONFIRM" =~ ^[Nn]$ ]]; then
    echo -e "${C_RED}✖ Setup Aborted.${C_RESET}"
    exit 1
fi

# --- EXECUTION ---
echo ""
print_step "2/4" "System Configuration"

print_task "Creating directory structure"
mkdir -p /etc/pterodactyl
print_status "OK"

print_task "Generating config.yml"
# Using 'tee' quietly
if ! tee /etc/pterodactyl/config.yml > /dev/null <<CFG
debug: false
uuid: ${UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: true
    cert: /etc/certs/wing/fullchain.pem
    key: /etc/certs/wing/privkey.pem
  upload_limit: 100
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '${REMOTE}'
CFG
then
    print_status "FAIL"
    echo -e "${C_RED}✖ Could not write config file.${C_RESET}"
    exit 1
fi
print_status "OK"

# --- SERVICE MANAGEMENT ---
print_step "3/4" "Service Management"

print_task "Enabling Wings service"
systemctl enable wings >/dev/null 2>&1
print_status "OK"

print_task "Starting Wings daemon"
if systemctl restart wings 2>/dev/null; then
    # Slight pause to let service initialize
    sleep 2
    if systemctl is-active --quiet wings; then
        print_status "OK"
    else
        print_status "FAIL"
        echo -e "${C_RED}✖ Service started but crashed immediately.${C_RESET}"
        journalctl -u wings --no-pager -n 5
        exit 1
    fi
else
    print_status "FAIL"
    echo -e "${C_RED}✖ Systemd failed to restart service.${C_RESET}"
    exit 1
fi

# --- SUMMARY ---
echo ""
echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
echo -e "${C_GREEN}${C_BOLD} ✔ WINGS INSTALLED SUCCESSFULLY${C_RESET}"
echo -e "${C_GRAY}──────────────────────────────────────────────────${C_RESET}"
echo ""
echo -e "  ${C_CYAN}➜ Commands:${C_RESET}"
echo -e "    Status  : ${C_WHITE}systemctl status wings${C_RESET}"
echo -e "    Logs    : ${C_WHITE}journalctl -u wings -f${C_RESET}"
echo -e "    Config  : ${C_WHITE}/etc/pterodactyl/config.yml${C_RESET}"
echo ""
echo -e "  ${C_BLUE}Thank you for using Nobita-Hosting!${C_RESET}"
echo ""

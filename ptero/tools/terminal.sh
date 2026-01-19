#!/bin/bash
set -e

# ==================================================
#  TERMINAL SHARING HUB | DASHBOARD UI
# ==================================================

# --- COLORS ---
C_RESET='\033[0m'
C_RED='\033[1;31m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_BLUE='\033[1;34m'
C_PURPLE='\033[1;35m'
C_CYAN='\033[1;36m'
C_WHITE='\033[1;37m'
C_GRAY='\033[1;90m'

# --- OS DETECTION ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Unsupported OS"; exit 1
fi

# --- UTILS ---
has() { command -v "$1" >/dev/null 2>&1; }

status_icon() {
    if has "$1"; then echo -e "${C_GREEN}✔${C_RESET}"; else echo -e "${C_GRAY}✖${C_RESET}"; fi
}

# --- INSTALLATION HANDLER ---
base_install() {
    if ! has curl || ! has wget || ! has tmux; then
        echo -e "${C_BLUE}➜ Installing base dependencies...${C_RESET}"
        case "$OS" in
            ubuntu|debian|kali)
                sudo apt update -y -qq >/dev/null
                sudo apt install -y curl wget sudo screen tmux -qq >/dev/null
                ;;
            centos|rocky|almalinux|fedora)
                sudo yum install -y curl wget sudo screen tmux -q
                ;;
        esac
    fi
}

# --- UI HEADER ---
draw_header() {
    clear
    local host=$(hostname)
    local ip=$(hostname -I | awk '{print $1}')
    
    echo -e "${C_CYAN}╔══════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_PURPLE}⚡ TERMINAL SHARING HUB v2.0${C_RESET}                                       ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╠══════════════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET} ${C_BLUE}HOST:${C_RESET} ${C_WHITE}$host${C_RESET}   ${C_BLUE}IP:${C_RESET} ${C_WHITE}$ip${C_RESET}                                         ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╚══════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

# ===================== TOOLS =====================

# 1. SSHX (Official)
sshx_run() {
    echo -e "${C_GREEN}▶ Launching sshx...${C_RESET}"
    curl -sSf https://sshx.io/get | sh -s run
}

# 2. TMATE (Session Sharing)
tmate_run() {
    if ! has tmate; then
        echo -e "${C_YELLOW}➜ Installing tmate...${C_RESET}"
        case "$OS" in
            ubuntu|debian) sudo apt install -y tmate ;;
            *) sudo yum install -y tmate ;;
        esac
    fi
    echo -e "${C_GREEN}▶ Starting tmate session...${C_RESET}"
    tmate
}

# 3. UPTERM (Secure Sharing)
upterm_run() {
    if ! has upterm; then
        echo -e "${C_YELLOW}➜ Installing upterm...${C_RESET}"
        curl -fsSL https://upterm.sh/install | sh
    fi
    echo -e "${C_GREEN}▶ Starting upterm host...${C_RESET}"
    upterm host
}

# 4. TTYD (Web Terminal)
ttyd_run() {
    if ! has ttyd; then
        echo -e "${C_YELLOW}➜ Installing ttyd...${C_RESET}"
        case "$OS" in
            ubuntu|debian) sudo apt install -y ttyd ;;
            *) 
                curl -L https://github.com/tsl0922/ttyd/releases/latest/download/ttyd.x86_64 -o ttyd
                chmod +x ttyd && sudo mv ttyd /usr/local/bin/
                ;;
        esac
    fi
    read -rp "🌐 Port (default 8080): " P
    P=${P:-8080}
    echo -e "${C_GREEN}▶ Web Terminal running at http://IP:$P${C_RESET}"
    ttyd -p "$P" bash
}

# 5. GOTTY (Web Terminal Alt)
gotty_run() {
    if ! has gotty; then
        echo -e "${C_YELLOW}➜ Installing gotty...${C_RESET}"
        wget -q https://github.com/yudai/gotty/releases/latest/download/gotty_linux_amd64.tar.gz
        tar -xzf gotty_linux_amd64.tar.gz
        chmod +x gotty && sudo mv gotty /usr/local/bin/
        rm gotty_linux_amd64.tar.gz
    fi
    echo -e "${C_GREEN}▶ Gotty started...${C_RESET}"
    gotty -w bash
}

# 6. SERVEO (Clientless Tunnel) - NEW
serveo_run() {
    echo -e "${C_PURPLE}ℹ️  Serveo requires no installation.${C_RESET}"
    echo -e "${C_GRAY}Forwarding local port 22 (SSH) to public URL...${C_RESET}"
    read -rp "⌨️  Custom Subdomain (optional, press Enter for random): " SUB
    
    if [ -z "$SUB" ]; then
        ssh -R 80:localhost:22 serveo.net
    else
        echo -e "${C_GREEN}▶ Trying https://$SUB.serveo.net ...${C_RESET}"
        ssh -R "$SUB":80:localhost:22 serveo.net
    fi
}

# 7. LOCALHOST.RUN (Clientless Tunnel) - NEW
localhost_run() {
    echo -e "${C_PURPLE}ℹ️  Localhost.run requires no installation.${C_RESET}"
    echo -e "${C_GRAY}Forwarding local SSH port...${C_RESET}"
    ssh -R 80:localhost:22 nokey@localhost.run
}

# 8. CLOUDFLARED
cloudflared_run() {
    if ! has cloudflared; then
        echo -e "${C_YELLOW}➜ Installing cloudflared...${C_RESET}"
        wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
        chmod +x cloudflared-linux-amd64
        sudo mv cloudflared-linux-amd64 /usr/local/bin/cloudflared
    fi
    echo -e "${C_GREEN}▶ Starting Quick Tunnel...${C_RESET}"
    cloudflared tunnel --url ssh://localhost:22
}

# ===================== MAIN MENU =====================

main_menu() {
    while true; do
        draw_header
        
        echo -e "${C_WHITE} INSTANT SHARING (COLLABORATION):${C_RESET}"
        echo -e " ${C_GREEN}[1]${C_RESET} sshx   $(status_icon sshx)   ${C_GRAY}(Best for live multiplayer)${C_RESET}"
        echo -e " ${C_GREEN}[2]${C_RESET} tmate  $(status_icon tmate)   ${C_GRAY}(Classic tmux sharing)${C_RESET}"
        echo -e " ${C_GREEN}[3]${C_RESET} upterm $(status_icon upterm)   ${C_GRAY}(Secure SSH sharing)${C_RESET}"
        echo ""
        
        echo -e "${C_WHITE} BROWSER TERMINALS (WEB):${C_RESET}"
        echo -e " ${C_BLUE}[4]${C_RESET} ttyd   $(status_icon ttyd)   ${C_GRAY}(Modern C++ backend)${C_RESET}"
        echo -e " ${C_BLUE}[5]${C_RESET} gotty  $(status_icon gotty)   ${C_GRAY}(Go backend)${C_RESET}"
        echo ""
        
        echo -e "${C_WHITE} TUNNELS (EXPOSE PORTS):${C_RESET}"
        echo -e " ${C_PURPLE}[6]${C_RESET} Serveo        ${C_GRAY}(Clientless SSH Tunnel)${C_RESET} ${C_YELLOW}★ NEW${C_RESET}"
        echo -e " ${C_PURPLE}[7]${C_RESET} Localhost.run ${C_GRAY}(Clientless SSH Tunnel)${C_RESET} ${C_YELLOW}★ NEW${C_RESET}"
        echo -e " ${C_PURPLE}[8]${C_RESET} Cloudflared   $(status_icon cloudflared)${C_RESET}"
        echo ""
        
        echo -e " ${C_GRAY}[0] Exit${C_RESET}"
        echo ""
        
        read -rp " ➤ Select Tool: " opt
        
        case "$opt" in
            1) sshx_run ;;
            2) tmate_run ;;
            3) upterm_run ;;
            4) ttyd_run ;;
            5) gotty_run ;;
            6) serveo_run ;;
            7) localhost_run ;;
            8) cloudflared_run ;;
            0) exit 0 ;;
            *) echo -e "${C_RED}Invalid option${C_RESET}"; sleep 1 ;;
        esac
        
        echo ""
        read -rp "Press Enter to return to menu..."
    done
}

# --- START ---
base_install
main_menu

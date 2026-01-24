
#!/bin/bash

# ==========================================
# 🐲 UI CONFIGURATION & COLORS
# ==========================================
# Colors
R="\e[31m"; G="\e[32m"; Y="\e[33m"
B="\e[34m"; M="\e[35m"; C="\e[36m"
W="\e[97m"; N="\e[0m"
BG_BLUE="\e[44m"

# Trap Ctrl+C
trap 'echo -e "\n${R} [!] Force exit detected.${N}"; exit 1' SIGINT

# ==========================================
# 🛠️ HELPER FUNCTIONS
# ==========================================

header() {
    clear
    echo -e "${C}"
    echo " ╔══════════════════════════════════════════════════════════╗"
    echo " ║                                                          ║"
    echo -e " ║  ${BG_BLUE}${W} 🐲 JEXACTYL MANAGER ${N}${C}                                 ║"
    echo " ║                                                          ║"
    echo " ╠══════════════════════════════════════════════════════════╣"
    echo -e " ║ ${B}User:${N} $(whoami)  ${B}Host:${N} $(hostname)  ${B}Date:${N} $(date +'%H:%M')   ${C}║"
    echo " ╚══════════════════════════════════════════════════════════╝"
    echo -e "${N}"
}

pause() {
    echo -e "\n${B} ──────────────────────────────────────────────────────────${N}"
    read -rp " ↩️  Press Enter to return..."
}

# ==========================================
# 🚀 ACTIONS
# ==========================================

install_panel() {
    header
    echo -e "\n${G} [ INSTALLATION MODE ] ${N}"
    echo -e " ${W}Starting Jexactyl Installation/Update process...${N}\n"
    
    # Add your actual install commands here
    # Example:
    # bash <(curl -s https://raw.githubusercontent.com/jexactyl/jexactyl/main/install.sh)
    
    echo -e " ${Y}⚠ No command configured yet. Add script in 'install_panel' function.${N}"
    pause
}

uninstall_panel() {
    header
    echo -e "\n${R} [ MAINTENANCE MODE ] ${N}"
    echo -e " ${W}Starting Uninstall / Backup Restore...${N}\n"
    
    # Add your actual commands here
    
    echo -e " ${Y}⚠ No command configured yet. Add script in 'uninstall_panel' function.${N}"
    pause
}

# ==========================================
# 🖥️ MAIN MENU
# ==========================================
while true; do
  header
  echo -e "${W} SELECT AN OPERATION:${N}\n"

  echo -e "  ${G}[ 1 ]${N}  🚀  Install"
  echo -e "  ${G}[ 2 ]${N}  🚀  Create admin user"
  echo -e "  ${G}[ 3 ]${N}  🚀  update"
  echo -e "  ${G}[ 4 ]${N}  🚀  Migration"

  echo -e "  ${R}[ 5 ]${N}  ♻️  Uninstall"
  echo -e ""
  echo -e "  ${R}[ 0 ]${N}  ❌  Exit Manager"
  
  echo -e "\n${C} ──────────────────────────────────────────────────────────${N}"
  read -p " 👉 Select Option: " choice

  case $choice in
    1) install_panel ;;
    2) uninstall_panel ;;
    0) 
       echo -e "\n${M} 👋 Exiting Jexactyl Manager.${N}"
       exit 0 
       ;;
    *) 
       echo -e "\n${R} ❌ Invalid Option!${N}"
       sleep 1
       ;;
  esac
done

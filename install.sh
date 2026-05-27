#!/usr/bin/env bash

set -e

########################################
# COLORS
########################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

########################################
# CONFIG
########################################

INSTALL_DIR="/opt/conduit"
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

########################################
# LOGO
########################################

clear

echo -e "${CYAN}"
echo " ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
echo "██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
echo "██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║   "
echo "██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║   "
echo "╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║   "
echo " ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝   "

echo -e "${GREEN}One‑Click Conduit Installer${NC}"
echo ""

########################################
# PROGRESS BAR
########################################

progress() {
    local duration=$1
    already_done() { for ((done=0; done<$elapsed; done++)); do printf "▇"; done }
    remaining() { for ((remain=$elapsed; remain<$duration; remain++)); do printf "-"; done }
    percentage() { printf "%s%%" $(( (($elapsed)*100)/($duration)*100/100 )); }

    for (( elapsed=1; elapsed<=$duration; elapsed++ )); do
        printf "\rProgress : ["
        already_done
        remaining
        printf "] "
        percentage
        sleep 0.05
    done
    printf "\n"
}

########################################
# ROOT CHECK
########################################


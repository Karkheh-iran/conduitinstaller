#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

INSTALL_DIR="/opt/conduit"

clear

echo -e "${CYAN}"
echo " ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
echo "██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
echo "██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║"
echo "██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║"
echo "╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║"
echo " ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝"
echo ""
echo -e "${GREEN}One Click Conduit Installer${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run as root${NC}"
  exit 1
fi

if [ -f /etc/debian_version ]; then
    echo -e "${GREEN}Debian/Ubuntu detected${NC}"
else
    echo -e "${RED}Unsupported OS${NC}"
    exit 1
fi

RAM_MB=$(free -m | awk '/^Mem:/{print $2}')

if [ "$RAM_MB" -lt 512 ]; then
    echo -e "${RED}Minimum 512MB RAM required${NC}"
    exit 1
fi

echo -e "${GREEN}RAM: ${RAM_MB}MB${NC}"

echo -e "${BLUE}Updating system...${NC}"

apt update -y

echo -e "${BLUE}Installing dependencies...${NC}"

apt install -y \
curl \
wget \
git \
ufw \
ca-certificates \
gnupg \
lsb-release

if ! command -v docker >/dev/null 2>&1; then

    echo -e "${BLUE}Installing Docker...${NC}"

    mkdir -p /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list

    apt update -y

    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

fi

systemctl enable docker
systemctl start docker

echo -e "${BLUE}Configuring firewall...${NC}"

ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw --force enable || true

mkdir -p ${INSTALL_DIR}

cd ${INSTALL_DIR}

echo -e "${BLUE}Downloading files...${NC}"

curl -fsSL https://raw.githubusercontent.com/Karkheh-iran/conduitinstaller/main/docker-compose.yml -o docker-compose.yml

curl -fsSL https://raw.githubusercontent.com/Karkheh-iran/conduitinstaller/main/.env.example -o .env

echo -e "${BLUE}Starting Conduit...${NC}"

docker compose up -d

sleep 10

if docker ps | grep -q conduit; then

    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Conduit Installed Successfully${NC}"
    echo -e "${GREEN}========================================${NC}"

else

    echo -e "${RED}Conduit Failed To Start${NC}"

    docker logs conduit

    exit 1

fi

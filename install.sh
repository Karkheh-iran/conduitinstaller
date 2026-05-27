#!/usr/bin/env bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

clear

echo -e "${CYAN}"
echo " ██████╗ ██████╗ ███╗   ██╗██████╗ ██╗   ██╗██╗████████╗"
echo "██╔════╝██╔═══██╗████╗  ██║██╔══██╗██║   ██║██║╚══██╔══╝"
echo "██║     ██║   ██║██╔██╗ ██║██║  ██║██║   ██║██║   ██║"
echo "██║     ██║   ██║██║╚██╗██║██║  ██║██║   ██║██║   ██║"
echo "╚██████╗╚██████╔╝██║ ╚████║██████╔╝╚██████╔╝██║   ██║"
echo " ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═════╝  ╚═════╝ ╚═╝   ╚═╝"
echo ""
echo -e "${GREEN}Conduit One Click Installer${NC}"
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

echo -e "${BLUE}Installing packages...${NC}"

apt install -y \
curl \
wget \
tar \
ufw

echo -e "${BLUE}Configuring firewall...${NC}"

ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw --force enable || true

mkdir -p /opt/conduit

cd /opt/conduit

echo -e "${BLUE}Downloading Conduit...${NC}"

wget -O conduit.tar.gz \
https://github.com/Psiphon-Labs/conduit/releases/latest/download/conduit-linux-amd64.tar.gz

echo -e "${BLUE}Extracting...${NC}"

tar -xzf conduit.tar.gz

chmod +x conduit

echo -e "${BLUE}Creating systemd service...${NC}"

cat > /etc/systemd/system/conduit.service <<EOF
[Unit]
Description=Psiphon Conduit
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/conduit
ExecStart=/opt/conduit/conduit
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable conduit
systemctl restart conduit

sleep 5

if systemctl is-active --quiet conduit; then

    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Conduit Installed Successfully${NC}"
    echo -e "${GREEN}Service: conduit${NC}"
    echo -e "${GREEN}========================================${NC}"

else

    echo -e "${RED}Conduit failed to start${NC}"

    journalctl -u conduit --no-pager -n 50

    exit 1

fi

#!/bin/bash

# رنگ‌ها برای نمایش بهتر پیام‌ها
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Starting Psiphon Conduit Installation...${NC}"

# بررسی دسترسی روت (Root)
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Please run this script as root (use sudo).${NC}"
  exit 1
fi

# تشخیص معماری سیستم (amd64 یا arm64)
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    CONDUIT_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ]; then
    CONDUIT_ARCH="arm64"
else
    echo -e "${RED}Unsupported architecture: $ARCH${NC}"
    exit 1
fi

echo -e "System architecture detected: ${GREEN}${CONDUIT_ARCH}${NC}"

# دانلود آخرین نسخه کاندوئیت
DOWNLOAD_URL="https://github.com/Psiphon-Inc/conduit/releases/latest/download/conduit-linux-${CONDUIT_ARCH}"
echo -e "${YELLOW}Downloading Conduit binary...${NC}"
wget -qO /usr/local/bin/conduit "$DOWNLOAD_URL"

# بررسی موفقیت‌آمیز بودن دانلود
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to download Conduit. Please check your internet connection.${NC}"
    exit 1
fi

# دادن دسترسی اجرا به فایل
chmod +x /usr/local/bin/conduit

# ایجاد سرویس systemd برای اجرای دائمی در پس‌زمینه
echo -e "${YELLOW}Creating systemd service...${NC}"
cat <<EOF > /etc/systemd/system/conduit.service
[Unit]
Description=Psiphon Conduit Relay Node
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/conduit
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# راه‌اندازی و فعال‌سازی سرویس
echo -e "${YELLOW}Starting Conduit service...${NC}"
systemctl daemon-reload
systemctl enable conduit > /dev/null 2>&1
systemctl start conduit

# توقف کوتاه برای اطمینان از اجرای سرویس
sleep 3

# بررسی وضعیت اجرای سرویس و نمایش به کاربر
if systemctl is-active --quiet conduit; then
    echo -e "------------------------------------------------------"
    echo -e "${GREEN}✅ SUCCESS: Psiphon Conduit is installed and running!${NC}"
    echo -e "------------------------------------------------------"
    echo -e "You can check the live logs anytime using this command:"
    echo -e "  ${YELLOW}journalctl -u conduit -f${NC}"
    echo -e "To stop the service, run:"
    echo -e "  ${YELLOW}systemctl stop conduit${NC}"
else
    echo -e "------------------------------------------------------"
    echo -e "${RED}❌ ERROR: Conduit installed but failed to start.${NC}"
    echo -e "Please check the logs using: journalctl -u conduit -e${NC}"
    echo -e "------------------------------------------------------"
fi

#!/bin/bash
# Must be run as root

# Exit on error
set -e

: "${BITCART_HOST?Error: BITCART_HOST environment variable is not set}"
: "${BITCART_ADMIN_EMAIL?Error: BITCART_ADMIN_EMAIL environment variable is not set}"
: "${BITCART_ADMIN_PASSWORD?Error: BITCART_ADMIN_PASSWORD environment variable is not set}"

# Some environment vars you need to set prior to calling the script
# Critical settings, must be included 
#export BITCART_HOST=myhost.mywebsite.com
#export BITCART_ADMIN_EMAIL=somebody@website.com
#export BITCART_ADMIN_PASSWORD=mypassword

# Required for email notificiations
#export SMTP_SERVER=''
#export SMTP_PORT=''
#export SMTP_TLS='' # True or False
#export SMTP_SSL='' # True or False
#export SMTP_USERNAME=''
#export SMTP_PASSWORD=''

# other settings
export BITCART_CRYPTOS=btc
export BTC_LIGHTNING=True
export BTC_LIGHTNING_LISTEN=0.0.0.0:9735
# used to include tor here but no longer do because it broke setup process
export BITCART_ADDITIONAL_COMPONENTS=btc-ln
export BTC_LIGHTNING_GOSSIP=true 
export BITCARTGEN_DOCKER_IMAGE=bitcart/docker-compose-generator:local
export BITCART_BITCOIN_EXPOSE=true
export BTC_DEBUG=true
export ALLOW_INCOMING_CHANNELS=true
export SMTP_FROM_EMAIL=$BITCART_ADMIN_EMAIL
export SMTP_TO_EMAIL=$BITCART_ADMIN_EMAIL

chmod +x run.sh
chmod +x update_liquidityhelper.sh

# enable automatic updates
apt install unattended-upgrades -y
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
dpkg-reconfigure -f noninteractive unattended-upgrades

# configure firewall
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 3000/tcp
ufw allow 4000/tcp
ufw allow 8000/tcp
# lightning
ufw allow 9735/tcp
# electrum
ufw deny 5000/tcp
ufw reload

# install bitcart
apt-get update && apt-get install -y git htop iotop python3-venv
mkdir -p /opt
cd /opt
if [ -d "bitcart-docker" ]; then echo "existing bitcart-docker folder found, pulling instead of cloning."; git pull; fi
if [ ! -d "bitcart-docker" ]; then echo "cloning bitcart-docker branch $1"; git clone -b "$1" https://github.com/BareBits/bitcart-docker.git; fi
cd bitcart-docker
./setup.sh
cd ..

# install liquidityhelper
cd /opt
if [ -d "liquidityhelper" ]; then echo "existing liquidityhelper folder found, pulling instead of cloning."; git pull; fi
if [ ! -d "liquidityhelper" ]; then echo "cloning liquidityhelper branch $1"; git clone -b "$1" https://github.com/BareBits/bitcart_liquidity.git; fi

# set variables
cd bitcart_liquidity
touch user_config.py
echo "ADMIN_EMAIL='$BITCART_ADMIN_EMAIL'">>user_config.py
echo "ADMIN_PASSWORD='$BITCART_ADMIN_PASSWORD'">>user_config.py
python3 -m venv .venv
source .venv/bin/activate
which python
pip install -r requirements.txt

# setup automatic run of liquidityhelper
set -euo pipefail

UNIT_FILE="/etc/systemd/system/liquidityhelper.service"

echo "Creating systemd unit file at ${UNIT_FILE}..."

cat > "${UNIT_FILE}" << 'EOF'
[Unit]
Description=LiquidityHelper
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=/opt/deploy_bitcart_liquidity/run.sh

# Restart behaviour
Restart=always
RestartSec=60

# Give up after 10 retries (StartLimitBurst) within a 700s window
# Window = RestartSec * (StartLimitBurst + 1) = 60 * 11 = 660s, using 700s for headroom
StartLimitIntervalSec=700
StartLimitBurst=10

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd daemon..."
systemctl daemon-reload
echo "Waiting for bitcart to start..."
sleep 60
echo "Enabling service to start at boot..."
systemctl enable liquidityhelper.service

echo ""
echo "Done. Service 'liquidityhelper' is installed and enabled."
echo ""
echo "Useful commands:"
echo "  Start now:    systemctl start liquidityhelper"
echo "  Check status: systemctl status liquidityhelper"
echo "  View logs:    journalctl -u liquidityhelper -f"
echo "  Disable:      systemctl disable liquidityhelper"


# setup automatic docker updates
mkdir -p ~/.local/bin/
wget -O ~/.local/bin/dockcheck.sh "https://raw.githubusercontent.com/mag37/dockcheck/main/dockcheck.sh" && chmod +x ~/.local/bin/dockcheck.sh
echo "1 1 * * * ~/.local/bin/dockcheck.sh -af > /var/log/dockerupdates.log" > /etc/cron.d/docker_update
echo "1 1 1 * * /opt/deploy_bitcart_liquidity/update_liquidityhelper.sh > /var/log/liquidityhelperupdate.log" > /etc/cron.d/docker_update



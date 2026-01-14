#!/bin/bash

# Critical settings, must be edited
export BITCART_HOST=myhost.mywebsite.com
export ADMIN_EMAIL=somebody@website.com
export ADMIN_PASSWORD=mypassword

# other settings
export BITCART_CRYPTOS=btc
export BTC_LIGHTNING=True
export BTC_LIGHTNING_LISTEN=0.0.0.0:9735
export BITCART_ADDITIONAL_COMPONENTS=tor,btc-ln
export BTC_LIGHTNING_GOSSIP=true 
export BITCARTGEN_DOCKER_IMAGE=bitcart/docker-compose-generator:local
export BITCART_BITCOIN_EXPOSE=true
export BTC_DEBUG=true
export ALLOW_INCOMING_CHANNELS=true

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
apt-get update && apt-get install -y git htop iotop
if [ -d "bitcart-docker" ]; then echo "existing bitcart-docker folder found, pulling instead of cloning."; git pull; fi
if [ ! -d "bitcart-docker" ]; then echo "cloning bitcart-docker"; git clone https://github.com/nothing-stops-this-train/bitcart-docker.git; fi
cd bitcart-docker
./setup.sh
cd ..

# install liquidityhelper
if [ -d "liquidityhelper" ]; then echo "existing liquidityhelper folder found, pulling instead of cloning."; git pull; fi
if [ ! -d "liquidityhelper" ]; then echo "cloning liquidityhelper"; git clone https://github.com/BareBits/bitcart_liquidity.git; fi
# set variables

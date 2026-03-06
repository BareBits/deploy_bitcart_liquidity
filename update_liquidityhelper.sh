#!/bin/bash
set -e
cd bitcart_liquidity 
old_head=$(git rev-parse HEAD)
git pull >> /dev/null
new_head=$(git rev-parse HEAD)

#date
if [ "$old_head" = "$new_head" ]; then
    echo "no updates for lhelper found"
    exit 0
else
    echo "liquidityhelper updated!"
    systemctl restart liquidityhelper
fi

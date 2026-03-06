#!/bin/bash
set -e
cd bitcart_liquidity 
old_head=$(git rev-parse HEAD)
git pull
new_head=$(git rev-parse HEAD)

if [ "$old_head" = "$new_head" ]; then
    # no updates
    exit 0
else
    # updated so we must restart
    systemctl restart liquidityhelper
fi

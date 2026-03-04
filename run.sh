#!/bin/bash

cd bitcart_liquidity
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install -r requirements.txt
python3 liquidityhelper.py


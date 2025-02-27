#!/bin/sh

python3 -m venv "forgevenv"
source ./forgevenv/bin/activate
python3 -m pip install --upgrade pip
pip3 install -r requirements.txt
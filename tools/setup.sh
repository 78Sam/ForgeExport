#!/bin/bash

cd ../
python3 -m venv detgenvenv
source detgenvenv/bin/activate
pip install -r requirements.txt
cd WhiffSuite
pip install -r requirements.txt
#!/bin/sh

/usr/bin/python3 -m venv "./../samvenv"
source ../samvenv/bin/activate
./../samvenv/bin/python3 -m pip install --upgrade pip
source ./../samvenv/bin/activate
pip3 install pandas
pip3 install numpy
pip3 install docker
pip3 install requests
pip3 install scikit-learn
pip3 install matplotlib
pip3 install yellowbrick
pip3 install torch
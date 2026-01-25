#!/bin/bash

# DNS の PostgreSQL が起動するまで待機
echo "Waiting for DNS PostgreSQL to be ready..."
until PGPASSWORD=pdns psql -h dns -U pdns -d pdns -c 'SELECT 1' > /dev/null 2>&1; do
    sleep 2
done
echo "DNS PostgreSQL is ready."

# admin ユーザーのパスワードを PHP で生成して更新
ADMIN_HASH=$(php -r "echo password_hash('admin', PASSWORD_DEFAULT);")
PGPASSWORD=pdns psql -h dns -U pdns -d pdns -c "UPDATE users SET password='$ADMIN_HASH' WHERE username='admin';"
echo "Admin password has been set."

# Apache を起動
apachectl start

# rsyslog を起動
rsyslogd

# ログを表示
tail -f /var/log/syslog

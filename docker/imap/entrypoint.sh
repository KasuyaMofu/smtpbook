#!/bin/bash

# 自身のIPアドレスを取得
SERVER_IP=$(hostname -i | awk '{print $1}')

# 受信プロキシをバックグラウンドで開始
rsyslogd
/usr/local/bin/smtp-receive-proxy \
    -incoming :25 \
    -postfix 127.0.0.1:10025 \
    -ip "$SERVER_IP" \
    2>&1 | logger -t receive-proxy &

postfix start
dovecot
sleep infinity

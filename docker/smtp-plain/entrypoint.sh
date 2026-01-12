#!/bin/bash

MYHOSTNAME=$(cat /etc/mailname)

# SMTPコマンドログ用milterをバックグラウンドで開始
rsyslogd
/usr/local/bin/smtp-command-output-milter -listen inet:10025@127.0.0.1 -hostname "$MYHOSTNAME" 2>&1 | logger -t milter &

postfix start
sleep infinity

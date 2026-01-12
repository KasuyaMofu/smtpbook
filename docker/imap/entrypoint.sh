#!/bin/bash

# SMTPプロトコルキャプチャをバックグラウンドで開始
rsyslogd
(tshark -p -l -i eth0 -t a -T text -f "tcp port 25" -Y smtp | sed -u -E -e 's/→ [0-9.]+  //' -e 's/^[0-9:. ]+10\.255/10\.255/' -e 's/\/IMF//' -e 's/ SMTP [0-9]+ / SMTP /' | logger -t smtp-dump) &

postfix start
tail ---disable-inotify -f /var/log/syslog

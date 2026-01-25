FROM kasuyamofu/smtpbook-base:latest

# Apache, PHP, PostgreSQL クライアントをインストール
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    apache2 \
    libapache2-mod-php \
    php-pgsql \
    php-intl \
    gettext \
    postgresql-client \
    curl \
    ca-certificates \
    unzip && \
    rm -rf /var/lib/apt/lists/*

# Poweradmin をダウンロードしてインストール
RUN curl -L https://github.com/poweradmin/poweradmin/archive/refs/tags/v3.9.0.tar.gz -o /tmp/poweradmin.tar.gz && \
    tar -xzf /tmp/poweradmin.tar.gz -C /var/www/html/ && \
    mv /var/www/html/poweradmin-3.9.0 /var/www/html/poweradmin && \
    rm /tmp/poweradmin.tar.gz && \
    rm -rf /var/www/html/poweradmin/install && \
    chown -R www-data:www-data /var/www/html/poweradmin

# Apache 設定
RUN a2enmod rewrite

# rsyslog をリモートログ受信用に設定
RUN printf '%s\n' \
    'module(load="imudp")' \
    'input(type="imudp" port="514")' \
    'module(load="imtcp")' \
    'input(type="imtcp" port="514")' \
    '$PreserveFQDN on' \
    '$EscapeControlCharactersOnReceive off' \
    '$template RemoteLog,"%timegenerated:::date-rfc3339% %HOSTNAME:1:24:fixed-width% %syslogtag:1:24:fixed-width%%msg%\n"' \
    '*.* /var/log/syslog;RemoteLog' \
    > /etc/rsyslog.d/50-remote.conf && \
    sed -i '/imklog/s/^/# /g' /etc/rsyslog.conf && \
    sed -i '/PrivDropTo/s/^/# /g' /etc/rsyslog.conf && \
    sed -i '/10.255.0.253/s/^/# /g' /etc/rsyslog.conf && \
    rm /etc/rsyslog.d/50-default.conf && \
    touch /var/log/syslog && chown syslog:adm /var/log/syslog

# Poweradmin 設定ファイルをコピー
COPY ./poweradmin-config.inc.php /var/www/html/poweradmin/inc/config.inc.php
RUN chown www-data:www-data /var/www/html/poweradmin/inc/config.inc.php

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 514/udp 514/tcp 80

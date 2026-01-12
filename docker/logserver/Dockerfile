FROM kasuyamofu/smtpbook-base:latest

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

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 514/udp 514/tcp

FROM kasuyamofu/smtpbook-proxy:latest AS proxy
FROM kasuyamofu/smtpbook-postfix:latest

ARG HOSTNAME RELAYHOST

## postfix settings
RUN echo "${HOSTNAME}" > /etc/mailname

RUN sed -i -E "/(myhostname|relayhost|smtpd_authorized_xclient_hosts)/d" /etc/postfix/main.cf && \
    echo "myhostname = ${HOSTNAME}" >> /etc/postfix/main.cf && \
    echo "relayhost = [${RELAYHOST}]:25" >> /etc/postfix/main.cf && \
    echo "smtpd_authorized_xclient_hosts = 127.0.0.1" >> /etc/postfix/main.cf

# Change Postfix to listen on port 10025
RUN sed -i 's/^smtp      inet/10025 inet/' /etc/postfix/master.cf

## rsyslog hostname
RUN echo "\$LocalHostName ${HOSTNAME}" >> /etc/rsyslog.conf

COPY --from=proxy /smtp-receive-proxy /usr/local/bin/

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 25/tcp

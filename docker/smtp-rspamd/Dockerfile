FROM kasuyamofu/smtpbook-proxy:latest AS proxy
FROM kasuyamofu/smtpbook-rspamd:latest

## Rspamd settings
RUN rm /etc/rspamd/override.d/dkim_signing.conf
COPY ./rspamd/key/*     /var/lib/rspamd/dkim/
COPY ./rspamd/local.d/* /etc/rspamd/local.d/
COPY ./rspamd/override.d/* /etc/rspamd/override.d/

ARG HOSTNAME NETWORK

## postfix settings
RUN echo "${HOSTNAME}" > /etc/mailname && \
    sed -i -E "/(myhostname|smtpd_milters|non_smtpd_milters)/d" /etc/postfix/main.cf && \
    echo "myhostname = ${HOSTNAME}" >> /etc/postfix/main.cf && \
    echo "smtpd_milters = inet:localhost:11332" >> /etc/postfix/main.cf && \
    echo "non_smtpd_milters = inet:localhost:11332" >> /etc/postfix/main.cf && \
    echo "smtpd_authorized_xclient_hosts = 127.0.0.1" >> /etc/postfix/main.cf
RUN sed -i "s/_NETWORK/${NETWORK}/" /etc/rspamd/override.d/options.inc

# Change Postfix to listen on port 10025
RUN sed -i 's/^smtp      inet/10025 inet/' /etc/postfix/master.cf

RUN chown -R rspamd:rspamd /var/lib/rspamd/ /etc/rspamd/ /var/log/rspamd/

## rsyslog hostname
RUN echo "\$LocalHostName ${HOSTNAME}" >> /etc/rsyslog.conf

COPY --from=proxy /smtp-receive-proxy /usr/local/bin/

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

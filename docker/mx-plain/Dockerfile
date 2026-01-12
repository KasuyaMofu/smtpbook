FROM kasuyamofu/smtpbook-milter:latest AS milter
FROM kasuyamofu/smtpbook-postfix:latest

ARG HOSTNAME RELAYHOST

## postfix settings
RUN echo "${HOSTNAME}"  > /etc/mailname

RUN sed -i -E "/(myhostname|relayhost)/d" /etc/postfix/main.cf && \
    echo "myhostname = ${HOSTNAME}" >> /etc/postfix/main.cf && \
    echo "relayhost = ${RELAYHOST}" >> /etc/postfix/main.cf && \
    echo "smtpd_milters = inet:127.0.0.1:10025" >> /etc/postfix/main.cf && \
    echo "non_smtpd_milters = inet:127.0.0.1:10025" >> /etc/postfix/main.cf && \
    echo "milter_default_action = accept" >> /etc/postfix/main.cf

## rsyslog hostname
RUN echo "\$LocalHostName ${HOSTNAME}" >> /etc/rsyslog.conf

COPY --from=milter /smtp-command-output-milter /usr/local/bin/

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 25/tcp

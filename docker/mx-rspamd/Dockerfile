FROM kasuyamofu/smtpbook-milter:latest AS milter
FROM kasuyamofu/smtpbook-rspamd:latest

RUN rm /etc/rspamd/override.d/milter_headers.conf

ARG HOSTNAME RELAYHOST ROLE

## postfix settings
RUN echo "${HOSTNAME}"  > /etc/mailname && \
    sed -i -E "/(myhostname|relayhost|smtpd_milters|non_smtpd_milters)/d" /etc/postfix/main.cf && \
    echo "myhostname = ${HOSTNAME}" >> /etc/postfix/main.cf && \
    echo "relayhost = ${RELAYHOST}" >> /etc/postfix/main.cf && \
    echo "smtpd_milters = inet:127.0.0.1:10025, inet:localhost:11332" >> /etc/postfix/main.cf && \
    echo "non_smtpd_milters = inet:127.0.0.1:10025, inet:localhost:11332" >> /etc/postfix/main.cf

RUN case "${ROLE}" in \
        spf)    rm /etc/rspamd/override.d/spf.conf ;;  \
        dkim)   rm /etc/rspamd/override.d/dkim.conf ;; \
        dmarc)  bash -c "rm /etc/rspamd/override.d/{spf.conf,dkim.conf,dmarc.conf}"  ;; \
        *)      echo "ROLE is not set" ;; \
    esac

## rsyslog hostname
RUN echo "\$LocalHostName ${HOSTNAME}" >> /etc/rsyslog.conf

COPY --from=milter /smtp-command-output-milter /usr/local/bin/

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

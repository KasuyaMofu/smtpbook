FROM kasuyamofu/smtpbook-milter:latest AS milter
FROM kasuyamofu/smtpbook-dovecot:latest

ARG HOSTNAME FORWARD_TO

## postfix settings
RUN sed -i -E "/(myhostname|mydestination)/d" /etc/postfix/main.cf
RUN DOMAIN=`echo ${HOSTNAME} | sed -E 's/.*\.([^.]+\.[^.]+)$/\1/'` && \
    echo "${HOSTNAME}" >> /etc/mailname && \
    echo "myhostname = ${HOSTNAME}"         >> /etc/postfix/main.cf && \
    echo "mydestination = \$myhostname, ${DOMAIN}, plain.${DOMAIN}, spf.${DOMAIN}, dkim.${DOMAIN}, dmarc.${DOMAIN}" >> /etc/postfix/main.cf && \
    if [ -n "${FORWARD_TO}" ] ; then \
    touch /home/user2/.forward && chown user2: /home/user2/.forward && \
    echo '\user2' >> /home/user2/.forward && \
    echo '"|/usr/sbin/sendmail -f user2+forward@'"${DOMAIN}"' user2@'"${FORWARD_TO}"'"' >> /home/user2/.forward \
    ; fi

RUN echo "smtpd_milters = inet:127.0.0.1:10025" >> /etc/postfix/main.cf && \
    echo "non_smtpd_milters = inet:127.0.0.1:10025" >> /etc/postfix/main.cf && \
    echo "milter_default_action = accept" >> /etc/postfix/main.cf

## rsyslog hostname
RUN echo "\$LocalHostName ${HOSTNAME}" >> /etc/rsyslog.conf

COPY --from=milter /smtp-command-output-milter /usr/local/bin/

COPY ./example/* /
COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 143/TCP

FROM kasuyamofu/smtpbook-pdns:latest

COPY zones/*.zone /etc/powerdns/zones/

ARG NETWORK
RUN sed -i "s/_NETWORK/${NETWORK}/g" /etc/powerdns/zones/*.zone

## rsyslog hostname
RUN echo "\$LocalHostName dns.test" >> /etc/rsyslog.conf

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 53/tcp 53/udp

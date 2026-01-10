FROM kasuyamofu/smtpbook-pdns:latest

COPY zones/*.zone /etc/powerdns/zones/

ARG NETWORK
RUN sed -i "s/_NETWORK/${NETWORK}/g" /etc/powerdns/zones/*.zone

COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 53/tcp 53/udp

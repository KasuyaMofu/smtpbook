.PHONY: up down stop view build kill build build/* scenario*/*

build/images:
	cd images && docker compose --env-file ../.env build base && docker compose --env-file ../.env build postfix &&  docker compose --env-file ../.env build && cd ..
build/docker:
	docker compose build
build: build/images build/docker

up:
	docker compose up
down:
	docker compose down
stop:
	docker compose stop
kill:
	docker compose kill
rebuild:
	docker compose kill ${TARGET} && docker compose down ${TARGET} && docker compose build ${TARGET} && docker compose up -d ${TARGET} 
view:
	docker compose exec b-imap /view.sh user1

log/a-smtp-dkim/rspamd:
	docker compose exec a-smtp-dkim tail -n 0 -f /var/log/rspamd/rspamd.log

log/b-mx-dkim/rspamd:
	docker compose exec b-mx-dkim tail -n 0 -f /var/log/rspamd/rspamd.log

remove:
	docker-compose down --rmi all --volumes --remove-orphans

##                                        subject     From                       To                  SMTP sever         (option) Envelope-From
## 1hop(client -> imap)
scenario1-1/send:
	docker compose exec a-client /send.sh scenario1-1 user1@a.test               user1@b.test        imap.b.test

## add MTA(relay) servers (client -> smtp -> mx -> imap)
scenario1-2/send:
	docker compose exec a-client /send.sh scenario1-2 user1@a.test               user1@b.test        plain.smtp.a.test

## SPF check
scenario2-1/send:
	docker compose exec a-client /send.sh scenario2-1 user1@a.test               user1@spf.b.test    plain.smtp.a.test

## SPF fail
scenario2-2/send:
	docker compose exec a-client /send.sh scenario2-2 user1@a.test               user1@spf.b.test    plain.smtp.x.test

## DKIM signed and verified
scenario3-1/send:
	docker compose exec a-client /send.sh scenario3-1 user1@pass.dkim.a.test    user1@dkim.b.test    dkim.smtp.a.test

## DKIM signed but fail (wrong DKIM record on DNS)
scenario3-2/send:
	docker compose exec a-client /send.sh scenario3-2 user1@fail.dkim.a.test    user1@dkim.b.test    dkim.smtp.a.test

## dmarc=pass(spf=pass, SPF aligned,      dkim=pass, DKIM aligned)
scenario4-1/send:
	docker compose exec a-client /send.sh scenario4-1 user1@pass.dkim.a.test    user1@dmarc.b.test   dkim.smtp.a.test

## dmarc=pass(spf=pass, SPF aligned,      dkim=fail)
scenario4-2/send:
	docker compose exec a-client /send.sh scenario4-2 user1@fail.dkim.a.test    user1@dmarc.b.test   dkim.smtp.a.test

## dmarc=pass(spf=fail,                   dkim=pass, DKIM aligned)
scenario4-3/send:
	docker compose exec a-client /send.sh scenario4-3 user1@pass.dkim.a.test    user1@dmarc.b.test   dkim.smtp.x.test

## dmarc=fail(spf=pass, SPF not aligned,  dkim=pass, DKIM not aligned)
scenario4-4/send:
	docker compose exec a-client /send.sh scenario4-4 user1@x.test              user1@dmarc.b.test   dkim.smtp.a.test      user1@a.test

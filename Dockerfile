FROM ubuntu:20.04

RUN  apt-get update \
     && apt-get install -y certbot curl jq nginx \
     && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80

COPY bin/certbot.sh /run.sh

ENTRYPOINT ["/run.sh"]
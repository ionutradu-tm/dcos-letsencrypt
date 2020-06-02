#!/bin/bash

set -e

if [[ -z "${EMAIL}" ]];then
    echo "The e-mail address is required"
    exit 1
fi

MARATHON_HOST=${MARATHON_HOST:-master.mesos:8080}
NGINX_PORT=${NGINX_PORT:-8080}

APP_PATH=$(echo ${MESOS_TASK_ID}| cut -d\. -f1| tr -s "_" "/")
echo $APP_PATH
MARATHON_URL="${MARATHON_HOST}/v2/apps/${APP_PATH}"
echo ${MARATHON_URL}
SSL_DOMAINS=$(curl -s  ${MARATHON_URL}| jq .app.labels.HAPROXY_0_VHOST| tr -d \"| tr -s " " ",")
echo "Found ${SSL_DOMAINS} SSL domains"
if [[ -z "${SSL_DOMAINS}" ]];then
   echo "No SSL domains found"
   exit 2
fi

sed -i 's/listen 80/listen '"${NGINX_PORT}"'/g' /etc/nginx/sites-available/default
nginx &


certbot certonly -n --standalone -w /var/lib/letsencrypt \
--agree-tos -m ${EMAIL} \
-d ${SSL_DOMAINS}
echo "cerbot exit code: $?"

for DOMAIN in $(ls -d  /etc/letsencrypt/live/*| grep -v README)
do
 SSL_DOMAIN=$(basename ${DOMAIN})
 cat /etc/letsencrypt/live/${SSL_DOMAIN}/fullchain.pem /etc/letsencrypt/live/${SSL_DOMAIN}/privkey.pem > /var/www/html/${SSL_DOMAIN}.pem
done

sleep 7d
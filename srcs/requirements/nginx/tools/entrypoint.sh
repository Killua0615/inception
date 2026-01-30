#!/bin/sh
set -eu

: "${DOMAIN_NAME:?}"

SSL_DIR="/etc/nginx/ssl"
CRT="${SSL_DIR}/${DOMAIN_NAME}.crt"
KEY="${SSL_DIR}/${DOMAIN_NAME}.key"

mkdir -p "$SSL_DIR" /run/nginx

if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}" \
    -keyout "$KEY" -out "$CRT"
fi

envsubst '$DOMAIN_NAME' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/http.d/default.conf

exec nginx -g 'daemon off;'

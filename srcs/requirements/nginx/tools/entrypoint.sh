#!/bin/sh
set -eu

# If empty/unspecified, terminate with an error
: "${DOMAIN_NAME:?}"

# Determine the location and name of the certificate file
SSL_DIR="/etc/nginx/ssl"
CRT="${SSL_DIR}/${DOMAIN_NAME}.crt"
KEY="${SSL_DIR}/${DOMAIN_NAME}.key"

mkdir -p "$SSL_DIR" /run/nginx

# If you do not have a certificate, create a self-signed certificate.
if [ ! -f "$CRT" ] || [ ! -f "$KEY" ]; then
  openssl req -x509 -nodes -newkey rsa:4096 -days 365 \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=Inception/CN=${DOMAIN_NAME}" \
    -keyout "$KEY" -out "$CRT"
fi

# envsubst is a tool that replaces ${DOMAIN_NAME} within templates with its actual value.
envsubst '$DOMAIN_NAME' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/http.d/default.conf

# Start Nginx "in the foreground" to make it the container's main process
exec nginx -g 'daemon off;'

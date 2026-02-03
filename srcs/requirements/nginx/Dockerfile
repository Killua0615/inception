FROM alpine:3.22

RUN apk update && apk add --no-cache nginx openssl gettext

RUN mkdir -p /etc/nginx/ssl /run/nginx

COPY conf/nginx.conf.template /etc/nginx/templates/nginx.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM alpine:3.22

RUN apk update && apk add --no-cache \
    php82 php82-fpm php82-phar php82-mysqli php82-curl php82-json php82-xml php82-mbstring php82-gd php82-zip php82-openssl php82-ctype \
    mariadb-client curl tar

RUN adduser -S -G www-data -H -s /sbin/nologin www-data || true

RUN ln -sf /usr/bin/php82 /usr/bin/php

RUN sed -i 's|^listen = .*|listen = 0.0.0.0:9000|' /etc/php82/php-fpm.d/www.conf \
 && sed -i 's|^;clear_env = no|clear_env = no|' /etc/php82/php-fpm.d/www.conf

RUN curl -sS -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM alpine:3.20

RUN apk update && apk add --no-cache mariadb mariadb-client

RUN mkdir -p /run/mysqld /var/lib/mysql \
    && adduser -D -H -s /sbin/nologin mysql || true \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

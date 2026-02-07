# base image
FROM alpine:3.21

# mariadb install
RUN apk update && apk add --no-cache mariadb mariadb-client

# Creating directories, users, and granting permissions required for startup
RUN mkdir -p /run/mysqld /var/lib/mysql \
    && adduser -D -H -s /sbin/nologin mysql || true \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

# copy script to container
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Indicates that the container uses port 3306
EXPOSE 3306

# Execute the entrypoint when the container starts
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

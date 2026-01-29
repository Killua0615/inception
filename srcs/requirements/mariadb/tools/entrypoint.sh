#!/bin/sh
set -eu

read_secret() {
  var="$1"
  file_var="${1}_FILE"
  eval "file=\${$file_var:-}"
  eval "val=\${$var:-}"
  if [ -n "${file:-}" ] && [ -f "$file" ]; then
    cat "$file"
  else
    printf "%s" "${val:-}"
  fi
}

MYSQLD_BIN="$(command -v mariadbd || command -v mysqld)"

ROOT_PASS="$(read_secret MYSQL_ROOT_PASSWORD)"
DB_PASS="$(read_secret MYSQL_PASSWORD)"

: "${MYSQL_DATABASE:?}"
: "${MYSQL_USER:?}"
: "${ROOT_PASS:?}"
: "${DB_PASS:?}"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
  if command -v mariadb-install-db >/dev/null 2>&1; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
  else
    mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null
  fi

  "$MYSQLD_BIN" --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"

  i=0
  until mysqladmin --socket=/run/mysqld/mysqld.sock ping >/dev/null 2>&1; do
    i=$((i+1))
    if [ "$i" -ge 30 ]; then
      echo "MariaDB init: server did not start" >&2
      kill "$pid" 2>/dev/null || true
      exit 1
    fi
    sleep 1
  done

  mysql --socket=/run/mysqld/mysqld.sock -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
FLUSH PRIVILEGES;
SQL

  mysqladmin --socket=/run/mysqld/mysqld.sock -uroot -p"${ROOT_PASS}" shutdown
  wait "$pid" || true
fi

exec "$MYSQLD_BIN" --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0

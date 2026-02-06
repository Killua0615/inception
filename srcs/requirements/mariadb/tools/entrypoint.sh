#!/bin/sh
set -eu

# This function allows secrets to be provided either as plain environment variables or as files, which is commonly used with Docker secrets.
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

# To ensure the correct executable is called when starting the MariaDB server later
MYSQLD_BIN="$(command -v mariadbd)"

ROOT_PASS="$(read_secret MYSQL_ROOT_PASSWORD)"
DB_PASS="$(read_secret MYSQL_PASSWORD)"

# : "${VAR:?}" exits with an error if the VAR is empty/unconfigured
: "${MYSQL_DATABASE:?}"
: "${MYSQL_USER:?}"
: "${ROOT_PASS:?}"
: "${DB_PASS:?}"

# Directory for storing PIDs, etc.
mkdir -p /run/mysqld
# It gives the mysql user permission to write to these directories.
chown -R mysql:mysql /run/mysqld /var/lib/mysql

# On the first startup only, it initializes MariaDB and applies the initial database and user configuration.
if [ ! -d /var/lib/mysql/mysql ]; then
  # Initialise the data directory (create system tables)
  if command -v mariadb-install-db >/dev/null 2>&1; then
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
  else
    mysql_install_db --user=mysql --datadir=/var/lib/mysql >/dev/null
  fi
  # Temporarily start MariaDB for initial configuration (disable external connections)
  "$MYSQLD_BIN" --user=mysql --datadir=/var/lib/mysql --skip-networking --socket=/run/mysqld/mysqld.sock &
  pid="$!"
  # Wait until startup is complete (up to 30 seconds)
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
  # Execute the initialisation SQL
  mysql --socket=/run/mysqld/mysqld.sock -uroot <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}';
FLUSH PRIVILEGES;
SQL
  #Stop the temporarily started MariaDB
  mysqladmin --socket=/run/mysqld/mysqld.sock -uroot -p"${ROOT_PASS}" shutdown
  wait "$pid" || true
fi

# Start the MariaDB server in "production mode" and make its process the container's main process (PID 1).
exec "$MYSQLD_BIN" --user=mysql --datadir=/var/lib/mysql --bind-address=0.0.0.0 --port=3306 --skip-networking=0
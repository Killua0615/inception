#!/bin/sh
set -eu
wp() { php -d memory_limit=1024M /usr/local/bin/wp "$@"; }

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

: "${DOMAIN_NAME:?}"
: "${MYSQL_DATABASE:?}"
: "${MYSQL_USER:?}"
: "${WP_TITLE:?}"
: "${WP_ADMIN_USER:?}"
: "${WP_ADMIN_EMAIL:?}"
: "${WP_USER:?}"
: "${WP_USER_EMAIL:?}"

case "$WP_ADMIN_USER" in
  *admin*|*Admin*|*administrator*|*Administrator*) echo "Invalid admin username" >&2; exit 1 ;;
esac

MYSQL_PASSWORD="$(read_secret MYSQL_PASSWORD)"
WP_ADMIN_PASSWORD="$(read_secret WP_ADMIN_PASSWORD)"
WP_USER_PASSWORD="$(read_secret WP_USER_PASSWORD)"

: "${MYSQL_PASSWORD:?}"
: "${WP_ADMIN_PASSWORD:?}"
: "${WP_USER_PASSWORD:?}"

WP_PATH="/var/www/html"

mkdir -p "$WP_PATH"
chown -R www-data:www-data "$WP_PATH" || true

if [ ! -f "$WP_PATH/wp-config.php" ]; then
  wp core download --path="$WP_PATH" --allow-root
  wp config create --path="$WP_PATH" \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$MYSQL_PASSWORD" \
    --dbhost="mariadb:3306" \
    --skip-check \
    --allow-root
fi

i=0
until mysqladmin ping -h mariadb -P 3306 -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -ge 30 ]; then
    echo "WordPress init: MariaDB not ready" >&2
    exit 1
  fi
  sleep 1
done

if ! wp core is-installed --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
  wp core install --path="$WP_PATH" \
    --url="https://$DOMAIN_NAME" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASSWORD" \
    --admin_email="$WP_ADMIN_EMAIL" \
    --skip-email \
    --allow-root

  if ! wp user get "$WP_USER" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
    wp user create "$WP_USER" "$WP_USER_EMAIL" --path="$WP_PATH" \
      --user_pass="$WP_USER_PASSWORD" \
      --role=author \
      --allow-root
  fi
fi

exec php-fpm82 -F

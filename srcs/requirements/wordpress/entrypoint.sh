#!/bin/bash
set -x
cd /usr/share/wordpress
if ! $(wp core is-installed --allow-root); then
  echo "in"
    wp core install  \
        --url=$HOST_NAME \
        --title="A Blog about You" \
        --admin_user="$WP_USER" \
        --admin_password="$WP_PASSWORD" \
        --admin_email="$WP_EMAIL" \
        --skip-email \
        --allow-root
    wp option set comment_moderation 0 --allow-root
    wp option set comment_whitelist 0 --allow-root
fi

if ! $(wp user get $NEW_WP_USER --field=login --allow-root); then
    echo "Creating new WordPress user: $NEW_WP_USER"
    wp user create $NEW_WP_USER $NEW_WP_EMAIL \
        --user_pass=$NEW_WP_PASSWORD \
        --role=author \
        --allow-root
fi

# start PHP-FPM
exec php-fpm8.2 -F

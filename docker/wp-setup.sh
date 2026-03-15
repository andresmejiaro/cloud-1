#!/bin/bash
# Runs once inside wp-cli container on first boot.
# Imports seed DB, swaps URLs, resets admin credentials from .env.
set -euo pipefail

SEED_FILE="/tmp/backup.sql"
FLAG_FILE="/var/www/html/.wp_setup_done"

# ── Already done? ─────────────────────────────────────────────────────────────
if [ -f "$FLAG_FILE" ]; then
  echo "[wp-setup] Already configured — skipping."
  exit 0
fi

# ── Wait for MySQL ─────────────────────────────────────────────────────────────
echo "[wp-setup] Waiting for MySQL..."
until php -r "
  \$c = new mysqli(
    '${WORDPRESS_DB_HOST}',
    '${WORDPRESS_DB_USER}',
    '${WORDPRESS_DB_PASSWORD}',
    '${WORDPRESS_DB_NAME}'
  );
  if (\$c->connect_error) exit(1);
" 2>/dev/null; do
  sleep 3
done
echo "[wp-setup] MySQL is up."

# ── Wait for WordPress files ───────────────────────────────────────────────────
until [ -f /var/www/html/wp-includes/version.php ]; do
  echo "[wp-setup] Waiting for WP files..."
  sleep 3
done

cd /var/www/html

# ── Import seed dump ───────────────────────────────────────────────────────────
if [ -f "$SEED_FILE" ]; then
  echo "[wp-setup] Importing seed database from $SEED_FILE..."
  wp db import "$SEED_FILE" --allow-root
  echo "[wp-setup] Seed import done."
else
  echo "[wp-setup] No seed file found at $SEED_FILE — installing fresh WordPress..."
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE:-My WordPress Site}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root
fi

# ── Replace placeholder URL with real WP_URL from .env ────────────────────────
echo "[wp-setup] Replacing URLs → ${WP_URL}"
wp search-replace '##WP_URL_PLACEHOLDER##' "${WP_URL}" \
  --all-tables --allow-root

# Also fix whatever URL the dump had stored (covers both cases)
CURRENT_URL=$(wp option get siteurl --allow-root 2>/dev/null || echo "")
if [ -n "$CURRENT_URL" ] && [ "$CURRENT_URL" != "${WP_URL}" ]; then
  echo "[wp-setup] Fixing stored URL: $CURRENT_URL → ${WP_URL}"
  wp search-replace "$CURRENT_URL" "${WP_URL}" --all-tables --allow-root
fi

wp option update siteurl "${WP_URL}" --allow-root
wp option update home    "${WP_URL}" --allow-root

# ── Reset admin credentials from .env (never trust dump's credentials) ────────
echo "[wp-setup] Setting admin credentials..."
wp user update "${WP_ADMIN_USER}" \
  --user_pass="${WP_ADMIN_PASSWORD}" \
  --user_email="${WP_ADMIN_EMAIL}" \
  --allow-root 2>/dev/null || \
wp user create "${WP_ADMIN_USER}" "${WP_ADMIN_EMAIL}" \
  --role=administrator \
  --user_pass="${WP_ADMIN_PASSWORD}" \
  --allow-root

# ── Harden: make sure no debug mode is left on ────────────────────────────────
wp config set WP_DEBUG false --raw --allow-root
wp config set WP_DEBUG_LOG false --raw --allow-root
wp config set WP_DEBUG_DISPLAY false --raw --allow-root

# ── Flush & done ──────────────────────────────────────────────────────────────
wp cache flush --allow-root
wp rewrite flush --allow-root

touch "$FLAG_FILE"
echo "[wp-setup] Setup complete. Site live at ${WP_URL}"

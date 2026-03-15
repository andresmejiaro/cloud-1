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

# ── Disable SSL verification for WP-CLI → MySQL (MySQL 8 self-signed cert) ───
# Write a wp-cli.yml that passes --ssl=false to every db command
mkdir -p /tmp/wpcli-home
cat > /tmp/wpcli-home/config.yml <<'WPCLI'
extra-php: |
  define( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT );
WPCLI
export WP_CLI_CONFIG_PATH=/tmp/wpcli-home/config.yml

# ── Wait for MySQL ─────────────────────────────────────────────────────────────
echo "[wp-setup] Waiting for MySQL..."
until php -r "
  mysqli_report(MYSQLI_REPORT_OFF);
  \$c = mysqli_init();
  mysqli_options(\$c, MYSQLI_OPT_SSL_VERIFY_SERVER_CERT, false);
  \$ok = @mysqli_real_connect(
    \$c,
    '${WORDPRESS_DB_HOST}',
    '${WORDPRESS_DB_USER}',
    '${WORDPRESS_DB_PASSWORD}',
    '${WORDPRESS_DB_NAME}',
    3306, NULL,
    MYSQLI_CLIENT_SSL_DONT_VERIFY_SERVER_CERT
  );
  exit(\$ok ? 0 : 1);
" 2>/dev/null; do
  echo "[wp-setup] MySQL not ready yet..."
  sleep 3
done
echo "[wp-setup] MySQL is up."

# ── Wait for WordPress files ───────────────────────────────────────────────────
until [ -f /var/www/html/wp-includes/version.php ]; do
  echo "[wp-setup] Waiting for WP files..."
  sleep 3
done

cd /var/www/html

# ── wp db import bypassing SSL ────────────────────────────────────────────────
# WP-CLI passes --ssl-mode via the extra-php define above, but the most
# reliable way for MySQL 8 inside Docker is to pipe directly via the mysql CLI.
import_db() {
  # Prefer the mysql binary (present in wordpress:cli image) with --ssl-mode=DISABLED
  if command -v mysql >/dev/null 2>&1; then
    echo "[wp-setup] Importing via mysql client (ssl-mode=DISABLED)..."
    mysql \
      --host="${WORDPRESS_DB_HOST}" \
      --user="${WORDPRESS_DB_USER}" \
      --password="${WORDPRESS_DB_PASSWORD}" \
      --ssl-mode=DISABLED \
      "${WORDPRESS_DB_NAME}" < "$SEED_FILE"
  else
    echo "[wp-setup] mysql binary not found, falling back to wp db import..."
    wp db import "$SEED_FILE" --allow-root
  fi
}

# ── Import seed dump ───────────────────────────────────────────────────────────
if [ -f "$SEED_FILE" ]; then
  echo "[wp-setup] Importing seed database from $SEED_FILE..."
  import_db
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

# Fix whatever URL the dump had stored
CURRENT_URL=$(wp option get siteurl --allow-root 2>/dev/null || echo "")
if [ -n "$CURRENT_URL" ] && [ "$CURRENT_URL" != "${WP_URL}" ]; then
  echo "[wp-setup] Fixing stored URL: $CURRENT_URL → ${WP_URL}"
  wp search-replace "$CURRENT_URL" "${WP_URL}" --all-tables --allow-root
fi

wp option update siteurl "${WP_URL}" --allow-root
wp option update home    "${WP_URL}" --allow-root

# ── Reset admin credentials from .env ─────────────────────────────────────────
echo "[wp-setup] Setting admin credentials..."
wp user update "${WP_ADMIN_USER}" \
  --user_pass="${WP_ADMIN_PASSWORD}" \
  --user_email="${WP_ADMIN_EMAIL}" \
  --allow-root 2>/dev/null || \
wp user create "${WP_ADMIN_USER}" "${WP_ADMIN_EMAIL}" \
  --role=administrator \
  --user_pass="${WP_ADMIN_PASSWORD}" \
  --allow-root

# ── Harden ────────────────────────────────────────────────────────────────────
wp config set WP_DEBUG false --raw --allow-root
wp config set WP_DEBUG_LOG false --raw --allow-root
wp config set WP_DEBUG_DISPLAY false --raw --allow-root

# ── Flush & done ──────────────────────────────────────────────────────────────
wp cache flush --allow-root
wp rewrite flush --allow-root

touch "$FLAG_FILE"
echo "[wp-setup] Setup complete. Site live at ${WP_URL}"

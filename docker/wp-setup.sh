#!/bin/bash
# Runs once inside wp-cli container on first boot.
# Creates wp-config.php, imports seed DB, resets admin credentials.
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

# ── Wait for WordPress core files ──────────────────────────────────────────────
until [ -f /var/www/html/wp-includes/version.php ]; do
  echo "[wp-setup] Waiting for WP core files..."
  sleep 3
done
echo "[wp-setup] WP core files present."

cd /var/www/html

# ── Create wp-config.php if it doesn't exist ──────────────────────────────────
# This is the step that prevents the "installation screen" — without it,
# WordPress doesn't know the DB credentials and shows the installer.
if [ ! -f wp-config.php ]; then
  echo "[wp-setup] Creating wp-config.php..."
  wp config create \
    --dbname="${WORDPRESS_DB_NAME}" \
    --dbuser="${WORDPRESS_DB_USER}" \
    --dbpass="${WORDPRESS_DB_PASSWORD}" \
    --dbhost="${WORDPRESS_DB_HOST}" \
    --skip-check \
    --allow-root
  echo "[wp-setup] wp-config.php created."
else
  echo "[wp-setup] wp-config.php already exists."
fi

# ── Import seed dump via mysql binary (bypasses SSL issue) ────────────────────
if [ -f "$SEED_FILE" ]; then
  echo "[wp-setup] Importing seed database from $SEED_FILE..."
  mysql \
    --host="${WORDPRESS_DB_HOST}" \
    --user="${WORDPRESS_DB_USER}" \
    --password="${WORDPRESS_DB_PASSWORD}" \
    --ssl-mode=DISABLED \
    "${WORDPRESS_DB_NAME}" < "$SEED_FILE"
  echo "[wp-setup] Seed import done."
else
  echo "[wp-setup] No seed file found — running fresh install..."
  wp core install \
    --url="${WP_URL}" \
    --title="${WP_TITLE:-My WordPress Site}" \
    --admin_user="${WP_ADMIN_USER}" \
    --admin_password="${WP_ADMIN_PASSWORD}" \
    --admin_email="${WP_ADMIN_EMAIL}" \
    --skip-email \
    --allow-root
fi

# ── Fix URLs in DB (in case dump has old/placeholder URL) ─────────────────────
echo "[wp-setup] Updating siteurl and home to ${WP_URL}..."
wp option update siteurl "${WP_URL}" --allow-root
wp option update home    "${WP_URL}" --allow-root

# ── Reset admin credentials ───────────────────────────────────────────────────
# The dump has user 'hola123' — update it, or create WP_ADMIN_USER if different
echo "[wp-setup] Resetting admin credentials..."
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

# ── Flush ─────────────────────────────────────────────────────────────────────
wp cache flush --allow-root
wp rewrite flush --allow-root

touch "$FLAG_FILE"
echo "[wp-setup] ✅ Done. Site live at ${WP_URL}"

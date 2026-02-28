<?php
define('DB_NAME', 'wordpress');
define('DB_USER', getenv('MYSQL_USER'));
define('DB_PASSWORD', getenv('MYSQL_PASSWORD'));
define('DB_HOST', getenv('DB_HOST'));
define('WP_CONTENT_DIR', '/var/lib/wordpress/wp-content');
?>
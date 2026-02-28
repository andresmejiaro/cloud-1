FROM debian:stable-slim


RUN apt-get update && apt-get install -y wordpress php-fpm php-curl php-gd php-intl \
    php-mbstring php-soap php-xml php-xmlrpc php-zip curl vim && mkdir -p /run/php/  && \
    chown www-data:www-data /run/php/ && chmod 755 /run/php/
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp
COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY config-amejia.42.fr.php /etc/wordpress/config-amejia.42.fr.php
COPY php.ini /etc/php/8.2/fpm/php.ini
COPY entrypoint.sh /usr/src/app/entrypoint.sh
RUN chmod +x /usr/src/app/entrypoint.sh
EXPOSE 9000

CMD ["/usr/src/app/entrypoint.sh"]
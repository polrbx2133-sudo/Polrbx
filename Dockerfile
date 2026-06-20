FROM php:8.3-apache

RUN a2enmod rewrite

RUN a2dismod mpm_event || true
RUN a2enmod mpm_prefork

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli zip soap \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . /var/www/html

RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN touch /var/www/html/.env

COPY start.sh /start.sh
RUN chmod +x /start.sh

RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

RUN { \
    echo '<Directory /var/www/html/public>'; \
    echo '    AllowOverride All'; \
    echo '    Require all granted'; \
    echo '</Directory>'; \
    } >> /etc/apache2/apache2.conf

RUN chown -R www-data:www-data /var/www/html/storage 2>/dev/null || true

EXPOSE 80

CMD ["/start.sh"]

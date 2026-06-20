FROM php:8.2-apache

RUN a2enmod rewrite

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY . /var/www/html

RUN composer install --no-dev --optimize-autoloader --no-interaction

RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

RUN { \
    echo '<Directory /var/www/html/public>'; \
    echo '    AllowOverride All'; \
    echo '    Require all granted'; \
    echo '</Directory>'; \
    } >> /etc/apache2/apache2.conf

RUN chown -R www-data:www-data /var/www/html/storage 2>/dev/null || true

RUN sed -ri 's/Listen 80/Listen ${PORT:-80}/g' /etc/apache2/ports.conf
RUN sed -ri 's/:80>/:${PORT:-80}>/g' /etc/apache2/sites-available/000-default.conf

EXPOSE 80

CMD ["sh", "-c", "apache2-foreground"]

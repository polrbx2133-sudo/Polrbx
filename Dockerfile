FROM php:8.3-apache

# Włącz mod_rewrite (potrzebne do .htaccess)
RUN a2enmod rewrite

# Naprawa konfliktu MPM (mod_php wymaga mpm_prefork, nie mpm_event)
RUN a2dismod mpm_event || true
RUN a2enmod mpm_prefork

# Zainstaluj rozszerzenia PHP potrzebne do MySQL, SOAP i typowych projektów PHP
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libxml2-dev \
    && docker-php-ext-install pdo pdo_mysql mysqli zip soap \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Zainstaluj Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Ustaw katalog roboczy
WORKDIR /var/www/html

# Skopiuj cały projekt do kontenera
COPY . /var/www/html

# Zainstaluj zależności PHP (bez dev-dependencies dla produkcji)
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Stwórz pusty plik .env - prawdziwe zmienne i tak biorą się z env. Railway (getenv())
RUN touch /var/www/html/.env

# Ustaw DocumentRoot na folder public/ (typowe dla tego typu projektów)
RUN sed -i 's!/var/www/html!/var/www/html/public!g' /etc/apache2/sites-available/000-default.conf

# Zezwól na .htaccess (AllowOverride All) w katalogu public
RUN { \
    echo '<Directory /var/www/html/public>'; \
    echo '    AllowOverride All'; \
    echo '    Require all granted'; \
    echo '</Directory>'; \
    } >> /etc/apache2/apache2.conf

# Uprawnienia dla storage/cache (jeśli projekt tego potrzebuje, jak Laravel-style apps)
RUN chown -R www-data:www-data /var/www/html/storage 2>/dev/null || true

EXPOSE 80

CMD ["bash", "-lc", "set -eux; a2dismod mpm_event mpm_worker || true; rm -f /etc/apache2/mods-enabled/mpm_event.* /etc/apache2/mods-enabled/mpm_worker.* || true; a2enmod mpm_prefork; sed -ri \"s/Listen 80/Listen ${PORT:-80}/g\" /etc/apache2/ports.conf; sed -ri \"s/:80>/:${PORT:-80}>/g\" /etc/apache2/sites-available/000-default.conf; apache2-foreground"]

FROM php:8.3.36-fpm-alpine3.23

# 1. Installazione librerie di runtime, Nginx e Supervisor
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    zip \
    unzip \
    imagemagick \
    libxml2 \
    libxslt \
    krb5 \
    openssl \
    libcurl

# 1b. Pacchetti dev temporanei per la compilazione (verranno rimossi dopo)
RUN apk add --no-cache \
    $PHPIZE_DEPS \
    imagemagick-dev \
    libxml2-dev \
    libxslt-dev \
    krb5-dev \
    openssl-dev \
    curl-dev \
    gettext-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    oniguruma-dev

# 2. Configurazione e installazione moduli PHP standard
RUN docker-php-ext-install -j$(nproc) \
    calendar \
    ctype \
    dom \
    exif \
    fileinfo \
    ftp \
    gettext \
    mysqli \
    pdo_mysql \
    shmop \
    sockets \
    sysvmsg \
    sysvsem \
    sysvshm \
    xsl \
    opcache \
    curl \
    mbstring \
    gd

# 3. Installazione Imagick tramite PECL e pulizia delle dipendenze di build
# Rimuoviamo le librerie -dev per mantenere l'immagine leggera
RUN pecl install imagick \
    && docker-php-ext-enable imagick \
    && apk del $PHPIZE_DEPS imagemagick-dev libxml2-dev libxslt-dev krb5-dev openssl-dev curl-dev gettext-dev

# 4. Creazione cartelle di lavoro e configurazione permessi
RUN mkdir -p /run/nginx /var/www/html \
    && chown -R www-data:www-data /var/www/html /run/nginx

WORKDIR /var/www/html

# 5. Copia delle configurazioni personalizzate
COPY nginx.conf /etc/nginx/http.d/default.conf
COPY supervisord.conf /etc/supervisord.conf

# Copia del codice sorgente (se non usato tramite volume)
COPY --chown=www-data:www-data . /var/www/html

EXPOSE 80

# 6. Avvio gestito da Supervisor per mantenere attivi Nginx e PHP-FPM
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]

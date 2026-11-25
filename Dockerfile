FROM registry.access.redhat.com/ubi8/ubi:8.10

ARG ROUNDCUBE_VERSION=1.6.20

ARG ROUNDCUBE_SHA256=46919c70c85609b57038903c4ecc4e1d7fa4e14c535fe5b14192d778dcd4a1ee

LABEL org.opencontainers.image.title="roundcube-fly"
LABEL org.opencontainers.image.description="Roundcube 1.6.20 sobre UBI 8.10, Apache y PHP-FPM"
LABEL org.opencontainers.image.version="1.6.20"
LABEL org.opencontainers.image.base.name="registry.access.redhat.com/ubi8/ubi:8.10"

# --------------------------------------------------
# Instalar Apache y PHP 8.2 desde Red Hat AppStream
# --------------------------------------------------

RUN dnf module enable -y php:8.2 \
    && dnf install -y \
        httpd \
        curl \
        tar \
        php \
        php-cli \
        php-ldap \
        php-common \
        php-fpm \
        php-mbstring \
        php-intl \
        php-xml \
        php-mysqlnd \
        php-gd \
        php-opcache \
        php-pecl-zip \
        libxml2 \
        openssl-libs \
        libcurl \
        libicu \
        libzip \
        oniguruma \
        sqlite-libs \
        zlib \
        apr \
        git \
        apr-util \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# --------------------------------------------------
# Configurar PHP-FPM
# --------------------------------------------------
RUN mkdir -p /run/php-fpm && \
    chown -R apache:apache /run/php-fpm

RUN sed -ri \
        's|^listen = .*|listen = 127.0.0.1:9000|' \
        /etc/php-fpm.d/www.conf \
    && sed -ri \
        's|^;?listen.allowed_clients = .*|listen.allowed_clients = 127.0.0.1|' \
        /etc/php-fpm.d/www.conf

# Configuración PHP
COPY config/php.ini /etc/php.ini

# --------------------------------------------------
# Configurar Apache + PHP-FPM
# --------------------------------------------------

RUN printf '%s\n' \
    'DirectoryIndex index.php index.html' \
    'ProxyRequests Off' \
    '<Directory "/var/www/html">' \
    '    AllowOverride All' \
    '    Require all granted' \
    '</Directory>' \
    '<FilesMatch "\.php$">' \
    '    SetHandler "proxy:fcgi://127.0.0.1:9000"' \
    '</FilesMatch>' \
    > /etc/httpd/conf.d/roundcube.conf

# Comprobar módulos de Apache
RUN httpd -M 2>&1 | grep -q proxy_fcgi_module \
    && httpd -t

# --------------------------------------------------
# Descargar Roundcube
# --------------------------------------------------

RUN set -eux; \
    curl -fsSL --retry 3 \
        "https://github.com/roundcube/roundcubemail/releases/download/${ROUNDCUBE_VERSION}/roundcubemail-${ROUNDCUBE_VERSION}-complete.tar.gz" \
        -o /tmp/roundcube.tar.gz; \
    echo "${ROUNDCUBE_SHA256}  /tmp/roundcube.tar.gz" | sha256sum -c -; \
    mkdir -p /var/www/html; \
    tar -xzf /tmp/roundcube.tar.gz \
        --strip-components=1 \
        -C /var/www/html; \
    rm -f /tmp/roundcube.tar.gz

# --------------------------------------------------
# Configuración de Roundcube
# --------------------------------------------------

COPY config/config.inc.php /var/www/html/config/config.inc.php

# --------------------------------------------------
# Directorios de datos y permisos
# --------------------------------------------------

RUN mkdir -p \
        /var/lib/roundcube/temp \
        /var/log/roundcube \
    && chown -R apache:apache \
        /var/www/html \
        /var/lib/roundcube \
        /var/log/roundcube \
    && chmod 0750 /var/lib/roundcube/temp \
    && chmod 0750 /var/log/roundcube

# --------------------------------------------------
# Verificaciones
# --------------------------------------------------

RUN php -v \
    && php -m \
    && php-fpm -t \
    && httpd -t \
    && rpm -q php php-fpm

# Copia los plugins a calendar
COPY plugins/libcalendaring /var/www/html/plugins/libcalendaring
COPY plugins/libkolab /var/www/html/plugins/libkolab
COPY plugins/calendar /var/www/html/plugins/calendar

# Recompilar roundcube con plugins
COPY launch.sh /root/launch.sh

RUN chmod 0755 /root/launch.sh

# Arranque de Apache y PHP-FPM
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh

# Puerto HTTP
EXPOSE 80

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

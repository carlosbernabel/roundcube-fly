# syntax=docker/dockerfile:1

# ============================================================
# Etapa 1: compilar PHP 8.2.35 con soporte para Apache
# ============================================================

FROM registry.access.redhat.com/ubi8/ubi:8.10 AS php-builder

ARG PHP_VERSION=8.2.35

ARG PHP_SHA256=5737b98601fe5ab1b8c5db0c82ed3158acb9283ed3081ffe2faffb9ac81455e6

RUN dnf install -y \
        gcc \
        make \
        autoconf \
        bison \
        re2c \
        tar \
        xz \
        curl \
        pkgconf-pkg-config \
        httpd-devel \
        apr-devel \
        apr-util-devel \
        libxml2-devel \
        openssl-devel \
        curl-devel \
        libicu-devel \
        oniguruma-devel \
        libzip-devel \
        sqlite-devel \
        zlib-devel \
    && dnf clean all \
    && rm -rf /var/cache/dnf

WORKDIR /usr/src

RUN curl -fsSL --retry 3 \
        "https://www.php.net/distributions/php-${PHP_VERSION}.tar.xz" \
        -o php.tar.xz \
    && echo "${PHP_SHA256}  php.tar.xz" | sha256sum -c - \
    && mkdir php \
    && tar -xf php.tar.xz -C php --strip-components=1 \
    && rm php.tar.xz

WORKDIR /usr/src/php

RUN ./configure \
        --prefix=/usr/local \
        --with-config-file-path=/usr/local/lib \
        --with-apxs2=/usr/bin/apxs \
        --with-openssl \
        --with-curl \
        --with-zlib \
        --with-zip \
        --with-iconv \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-sqlite \
        --with-sqlite3 \
        --enable-mbstring \
        --enable-intl \
        --enable-exif \
        --enable-opcache \
        --disable-cgi \
    && make -j"$(nproc)" \
    && make install \
    && install -m 0644 php.ini-production /usr/local/lib/php.ini \
    && php -v \
    && php -m


# ============================================================
# Etapa 2: imagen final con UBI 8.10 + Apache + PHP + Roundcube
# ============================================================

FROM registry.access.redhat.com/ubi8/ubi:8.10

ARG PHP_VERSION=8.2.35
ARG ROUNDCUBE_VERSION=1.6.20

ARG ROUNDCUBE_SHA256=46919c70c85609b57038903c4ecc4e1d7fa4e14c535fe5b14192d778dcd4a1ee

LABEL org.opencontainers.image.title="roundcube-fly"
LABEL org.opencontainers.image.description="Roundcube 1.6.20 sobre UBI 8.10, Apache y PHP"
LABEL org.opencontainers.image.version="1.6.20"
LABEL org.opencontainers.image.base.name="registry.access.redhat.com/ubi8/ubi:8.10"

# Instalar Apache y bibliotecas necesarias para ejecutar PHP.

RUN dnf install -y \
        httpd \
        curl \
        libxml2 \
        openssl-libs \
        libcurl \
        libicu \
        libzip \
        oniguruma \
        sqlite-libs \
        zlib \
        apr \
        apr-util \
    && dnf clean all \
    && rm -rf /var/cache/dnf

# Copiar PHP compilado y su módulo para Apache.

COPY --from=php-builder /usr/local/ /usr/local/
COPY --from=php-builder /usr/lib64/httpd/modules/libphp.so \
    /usr/lib64/httpd/modules/libphp.so

# Configurar PHP.

COPY config/php.ini /usr/local/lib/php.ini

# Configurar Apache para utilizar mod_php y MPM prefork.

RUN set -eux; \
    sed -ri \
        's/^([[:space:]]*)LoadModule mpm_event_module/\1#LoadModule mpm_event_module/' \
        /etc/httpd/conf.modules.d/00-mpm.conf; \
    sed -ri \
        's/^#[[:space:]]*(LoadModule mpm_prefork_module)/\1/' \
        /etc/httpd/conf.modules.d/00-mpm.conf; \
    printf '%s\n' \
        'LoadModule php_module modules/libphp.so' \
        'AddHandler php-script .php' \
        'DirectoryIndex index.php index.html' \
        '<FilesMatch \.php$>' \
        '    SetHandler application/x-httpd-php' \
        '</FilesMatch>' \
        > /etc/httpd/conf.modules.d/10-php.conf; \
    httpd -t

# Descargar Roundcube 1.6.20 LTS y verificar su integridad.

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

# Configuración de Roundcube.

COPY config/config.inc.php /var/www/html/config/config.inc.php

# Directorios de datos y permisos.

RUN mkdir -p \
        /var/lib/roundcube/temp \
        /var/log/roundcube \
    && chown -R apache:apache \
        /var/www/html \
        /var/lib/roundcube \
        /var/log/roundcube \
    && chmod 0750 /var/lib/roundcube/temp \
    && chmod 0750 /var/log/roundcube \
    && php -v \
    && php -m \
    && httpd -t

# Puerto HTTP.

EXPOSE 80

# Apache permanece en primer plano para que el contenedor
# funcione correctamente en Kubernetes.

CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]

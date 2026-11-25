#!/bin/bash
set -eux

ROUNDCUBE_DIR="/var/www/"
PLUGIN_DIR="${ROUNDCUBE_DIR}/plugins"

cd "${ROUNDCUBE_DIR}"

# ==========================================
# INSTALL SYSTEM DEPENDENCIES
# ==========================================

#dnf install -y \
#    php \
#    php-cli \
#    php-zip \
#    php-json \
#    php-mbstring \
#    php-xml \
#    php-intl \
#    php-curl \
#    wget \
#    unzip \
#    git

# ==========================================
# INSTALL COMPOSER
# ==========================================

php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

php composer-setup.php \
    --install-dir=/usr/local/bin \
    --filename=composer

php -r "unlink('composer-setup.php');"

# ==========================================
# DOWNLOAD ROUNDCUBE CALENDAR COMPONENTS
# ==========================================

cd "${PLUGIN_DIR}"

# libcalendaring
if [ ! -d libcalendaring ]; then
    git clone https://github.com/roundcube/libcalendaring.git
fi

# libkolab
if [ ! -d libkolab ]; then
    git clone https://github.com/roundcube/libkolab.git
fi

# calendar
if [ ! -d calendar ]; then
    git clone https://github.com/roundcube/calendar.git
fi

# ==========================================
# CONFIGURE CALENDAR PLUGINS
# ==========================================

cd "${PLUGIN_DIR}/libcalendaring"
ln -sfn "${ROUNDCUBE_DIR}/program" ./

cd "${PLUGIN_DIR}/libkolab"
ln -sfn "${ROUNDCUBE_DIR}/program" ./

cd "${PLUGIN_DIR}/calendar"
ln -sfn "${ROUNDCUBE_DIR}/program" ./

# ==========================================
# INSTALL PLUGIN DEPENDENCIES
# ==========================================

cd "${PLUGIN_DIR}/libcalendaring"
echo y |composer install --no-dev --optimize-autoloader

cd "${PLUGIN_DIR}/libkolab"
echo y | composer install --no-dev --optimize-autoloader

cd "${PLUGIN_DIR}/calendar"
echo y | composer install --no-dev --optimize-autoloader

# ==========================================
# INSTALL LESS
# ==========================================

cd "${ROUNDCUBE_DIR}"

dnf module enable nodejs:18 -y
dnf install -y nodejs npm

npm install -g less
npm install -g less-plugin-clean-css

# ==========================================
# COMPILE CSS
# ==========================================

lessc --rewrite-urls=all \
    --clean-css="--s1 --advanced" \
    plugins/libkolab/skins/elastic/libkolab.less \
    > plugins/libkolab/skins/elastic/libkolab.min.css

# ==========================================
# UPDATE ROUNDCUBE
# ==========================================

cd "${ROUNDCUBE_DIR}"

composer config audit.block-insecure false

composer update || true

composer require sabre/dav "~3.1.3" || true

# ==========================================
# FINISH
# ==========================================

echo "=========================================="
echo "Roundcube Calendar installation completed"
echo "=========================================="


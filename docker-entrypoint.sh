#!/bin/bash

set -u

FLAG_FILE="/var/www/.initialized"

if [ ! -f "$FLAG_FILE" ]; then
    cd /var/www/roundcube
    # Ejecuta el comando PHP para inicializar la base de datos
    php bin/initdb.sh --dir=SQL --create || true
    # Init db calendar
    php bin/initdb.sh --dir=plugins/calendar/drivers/database/SQL/ --create || true
#    mkdir -p "$(dirname "$FLAG_FILE")"
    touch "$FLAG_FILE"

    bash /root/launch.sh
fi


# Arrancar PHP-FPM
php-fpm --nodaemonize &
FPM_PID=$!

# Arrancar Apache
httpd -DFOREGROUND &
HTTPD_PID=$!

# Gestión de señales
shutdown() {
    echo "Stopping Roundcube services..."

    kill -TERM "$HTTPD_PID" "$FPM_PID" 2>/dev/null || true

    wait "$HTTPD_PID" 2>/dev/null || true
    wait "$FPM_PID" 2>/dev/null || true
}

trap shutdown TERM INT

# Esperar a que termine alguno de los procesos
wait -n "$FPM_PID" "$HTTPD_PID"
STATUS=$?

shutdown

exit "$STATUS"


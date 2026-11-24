#!/bin/bash

set -u

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


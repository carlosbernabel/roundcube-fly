<?php

$config = [];

/*
 * Nombre de la aplicación.
 */
$config['product_name'] = 'Roundcube Fly';

/*
 * Base de datos.
 *
 * Ejemplo de DSN para MySQL:
 * mysql://usuario:password@servidor:3306/roundcube
 */
$config['db_dsnw'] = getenv('ROUNDCUBEMAIL_DB_DSNW') ?: '';

/*
 * Servidor IMAP.
 *
 * Ejemplo:
 * ssl://imap.example.com
 */
$config['default_host'] = getenv('ROUNDCUBEMAIL_DEFAULT_HOST') ?: '';

/*
 * Servidor SMTP.
 *
 * Ejemplo:
 * tls://smtp.example.com
 */
$config['smtp_server'] = getenv('ROUNDCUBEMAIL_SMTP_SERVER') ?: '';

$config['smtp_port'] = (int) (
    getenv('ROUNDCUBEMAIL_SMTP_PORT') ?: 587
);

/*
 * Utiliza las credenciales del usuario autenticado
 * para enviar correo mediante SMTP.
 */
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';

/*
 * Clave de cifrado de Roundcube.
 *
 * Configurar mediante una variable de entorno secreta.
 */
$config['des_key'] = getenv('ROUNDCUBEMAIL_DES_KEY') ?: '';

/*
 * Directorios de datos fuera del directorio público.
 */
$config['temp_dir'] = '/var/lib/roundcube/temp';
$config['log_dir'] = '/var/log/roundcube';

/*
 * Configuración de registros.
 */
$config['log_driver'] = 'file';

/*
 * Configuración de interfaz.
 */
$config['skin'] = 'elastic';

/*
 * Desactivar el instalador web.
 */
$config['enable_installer'] = false;

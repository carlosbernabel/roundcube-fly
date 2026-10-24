# roundcube-fly

Imagen de Roundcube Webmail construida sobre:

- Red Hat UBI 8.10
- Apache HTTP Server
- PHP 8.2.35
- Roundcube 1.6.20 LTS

## Construcción

La imagen se construye automáticamente mediante GitHub Actions
y se publica en Docker Hub.

## Versiones

- Base: registry.access.redhat.com/ubi8/ubi:8.10
- PHP: 8.2.35
- Roundcube: 1.6.20

## Configuración

La aplicación se configura mediante variables de entorno.

Variables disponibles:

- ROUNDCUBEMAIL_DB_DSNW
- ROUNDCUBEMAIL_DEFAULT_HOST
- ROUNDCUBEMAIL_SMTP_SERVER
- ROUNDCUBEMAIL_SMTP_PORT
- ROUNDCUBEMAIL_DES_KEY

No guardes contraseñas ni claves privadas en el repositorio.

## Base de datos

Antes de utilizar Roundcube, crea la base de datos y aplica
el esquema SQL correspondiente a la versión 1.6.20.

Los esquemas incluidos en la distribución se encuentran
en el directorio SQL de Roundcube.

## Kubernetes

La imagen publicada en Docker Hub se puede utilizar desde
un Deployment de Kubernetes.

Se recomienda utilizar una etiqueta específica de versión
o de commit, en lugar de depender únicamente de latest.

## Seguridad

- Verificación SHA-256 del código fuente de PHP.
- Verificación SHA-256 del paquete de Roundcube.
- Configuración externa mediante variables de entorno.
- No incluir credenciales en la imagen.

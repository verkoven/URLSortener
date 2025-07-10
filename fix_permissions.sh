#!/bin/bash

# Script para configurar permisos correctos en el acortador de URLs
# fix_permissions.sh

echo "🔧 Configuración de permisos para el acortador de URLs"
echo "====================================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Detectar el usuario del servidor web
if [ -d "/etc/apache2" ]; then
    WEB_USER="www-data"
    WEB_GROUP="www-data"
    echo -e "${GREEN}Detectado: Apache${NC}"
elif [ -d "/etc/nginx" ]; then
    WEB_USER="www-data"
    WEB_GROUP="www-data"
    echo -e "${GREEN}Detectado: Nginx${NC}"
else
    WEB_USER="www-data"
    WEB_GROUP="www-data"
    echo -e "${YELLOW}No se detectó servidor, usando www-data por defecto${NC}"
fi

# Obtener usuario actual
CURRENT_USER=$(whoami)

echo ""
echo -e "${BLUE}Usuario actual: $CURRENT_USER${NC}"
echo -e "${BLUE}Usuario web: $WEB_USER${NC}"
echo -e "${BLUE}Grupo web: $WEB_GROUP${NC}"
echo ""

# Preguntar modo de ejecución
echo -e "${YELLOW}¿Cómo deseas configurar los permisos?${NC}"
echo "1) Desarrollo (permisos más relajados)"
echo "2) Producción (permisos más estrictos)"
echo "3) Cancelar"
read -p "> " modo

if [[ $modo == "3" ]]; then
    echo -e "${YELLOW}Operación cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}Aplicando permisos...${NC}"

# Cambiar propietario
if [[ $modo == "2" ]]; then
    # Producción: todo es del usuario web
    echo "- Cambiando propietario a $WEB_USER:$WEB_GROUP"
    sudo chown -R $WEB_USER:$WEB_GROUP .
else
    # Desarrollo: usuario actual con grupo web
    echo "- Cambiando propietario a $CURRENT_USER:$WEB_GROUP"
    sudo chown -R $CURRENT_USER:$WEB_GROUP .
fi

# Permisos base para directorios
echo "- Configurando permisos de directorios (755)"
find . -type d -exec chmod 755 {} \;

# Permisos base para archivos
echo "- Configurando permisos de archivos (644)"
find . -type f -exec chmod 644 {} \;

# Archivos PHP ejecutables (solo si es necesario)
echo "- Configurando archivos PHP (644)"
find . -name "*.php" -type f -exec chmod 644 {} \;

# Archivos de configuración más restrictivos
echo "- Asegurando archivos sensibles (640)"
[ -f "conf.php" ] && chmod 640 conf.php
[ -f ".env" ] && chmod 640 .env
[ -f "config.php" ] && chmod 640 config.php

# Directorio admin más restrictivo
if [ -d "admin" ]; then
    echo "- Asegurando directorio admin"
    chmod 750 admin
    find admin -type f -name "*.php" -exec chmod 640 {} \;
fi

# Si existe directorio de uploads
if [ -d "uploads" ]; then
    echo "- Configurando directorio uploads (775)"
    chmod 775 uploads
fi

# Si existe directorio de logs
if [ -d "logs" ]; then
    echo "- Configurando directorio logs (775)"
    chmod 775 logs
fi

# Archivos de script bash ejecutables
echo "- Haciendo scripts ejecutables"
find . -name "*.sh" -type f -exec chmod 755 {} \;

# Proteger .htaccess si existe
if [ -f ".htaccess" ]; then
    echo "- Protegiendo .htaccess"
    chmod 644 .htaccess
fi

# Eliminar permisos de ejecución de archivos que no deben tenerlo
echo "- Quitando permisos de ejecución innecesarios"
find . -name "*.txt" -o -name "*.md" -o -name "*.json" -o -name "*.xml" | xargs -r chmod 644

echo ""
echo -e "${GREEN}✅ Permisos configurados correctamente${NC}"
echo ""

# Mostrar resumen
echo -e "${BLUE}Resumen de permisos:${NC}"
echo "- Directorios: 755 (rwxr-xr-x)"
echo "- Archivos PHP: 644 (rw-r--r--)"
echo "- Archivos sensibles: 640 (rw-r-----)"
echo "- Directorio admin: 750 (rwxr-x---)"
echo "- Scripts bash: 755 (rwxr-xr-x)"

if [[ $modo == "2" ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Modo producción activado${NC}"
    echo "- Los archivos pertenecen a $WEB_USER"
    echo "- Para editar archivos, usa: sudo nano archivo.php"
fi

echo ""
echo "🏁 Finalizado"

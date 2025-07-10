#!/bin/bash

# Script para establecer los permisos correctos del acortador de URLs
# Ejecutar con sudo

echo "🔐 Configurando permisos del Acortador de URLs"
echo "=============================================="
echo ""

# Verificar si se ejecuta con sudo
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Por favor ejecuta este script con sudo"
    echo "   Uso: sudo ./set_permissions.sh"
    exit 1
fi

# Directorio base
BASE_DIR="/var/www/html/acortador"

# Verificar que estamos en el directorio correcto
if [ ! -f "$BASE_DIR/index.php" ]; then
    echo "❌ Error: No se encuentra el directorio del acortador"
    echo "   Asegúrate de que el path sea: $BASE_DIR"
    exit 1
fi

echo "📁 Directorio base: $BASE_DIR"
echo ""

# Cambiar propietario a www-data
echo "👤 Estableciendo propietario www-data..."
chown -R www-data:www-data $BASE_DIR

# Permisos para directorios
echo "📂 Configurando permisos de directorios..."
find $BASE_DIR -type d -exec chmod 755 {} \;

# Permisos para archivos PHP
echo "📄 Configurando permisos de archivos PHP..."
find $BASE_DIR -name "*.php" -exec chmod 644 {} \;

# Permisos para archivos de configuración
echo "⚙️  Configurando permisos especiales..."
chmod 644 $BASE_DIR/conf.php
chmod 644 $BASE_DIR/robots.txt
chmod 644 $BASE_DIR/README.md
chmod 644 $BASE_DIR/favicon.ico

# Permisos especiales para el directorio de logs
echo "📝 Configurando permisos de logs..."
chmod 755 $BASE_DIR/log
chmod 666 $BASE_DIR/log/app.log
chmod 666 $BASE_DIR/log/test.log

# Verificar permisos
echo ""
echo "✅ Permisos establecidos. Verificando..."
echo ""
echo "📊 Resumen de permisos:"
echo "----------------------"
ls -la $BASE_DIR/
echo ""
echo "📁 Directorio admin/:"
ls -la $BASE_DIR/admin/
echo ""
echo "📁 Directorio log/:"
ls -la $BASE_DIR/log/

echo ""
echo "✨ ¡Permisos configurados correctamente!"
echo ""
echo "📋 Configuración aplicada:"
echo "   - Propietario: www-data:www-data"
echo "   - Directorios: 755 (rwxr-xr-x)"
echo "   - Archivos PHP: 644 (rw-r--r--)"
echo "   - Logs: 666 (rw-rw-rw-)"

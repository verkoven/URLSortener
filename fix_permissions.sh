#!/bin/bash

# Script para configurar permisos correctos en el acortador de URLs
# fix_permissions.sh - Versión final completa

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

# Verificar archivos importantes
echo -e "${YELLOW}Verificando archivos principales...${NC}"
[ -f "index.php" ] && echo -e "${GREEN}✓ index.php${NC}" || echo -e "${RED}✗ index.php${NC}"
[ -f "redirect.php" ] && echo -e "${GREEN}✓ redirect.php${NC}" || echo -e "${RED}✗ redirect.php${NC}"
[ -f "stats.php" ] && echo -e "${GREEN}✓ stats.php${NC}" || echo -e "${RED}✗ stats.php${NC}"
[ -f "conf.php" ] && echo -e "${GREEN}✓ conf.php${NC}" || echo -e "${RED}✗ conf.php${NC}"
[ -f "menu.php" ] && echo -e "${GREEN}✓ menu.php${NC}" || echo -e "${RED}✗ menu.php${NC}"
[ -f ".htaccess" ] && echo -e "${GREEN}✓ .htaccess${NC}" || echo -e "${RED}✗ .htaccess${NC}"
[ -d "admin" ] && echo -e "${GREEN}✓ directorio admin/${NC}" || echo -e "${RED}✗ directorio admin/${NC}"
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

# Archivos PHP principales (accesibles públicamente)
echo "- Configurando archivos PHP principales (644)"
[ -f "index.php" ] && chmod 644 index.php
[ -f "redirect.php" ] && chmod 644 redirect.php
[ -f "stats.php" ] && chmod 644 stats.php
[ -f "menu.php" ] && chmod 644 menu.php
[ -f "test_redirect.php" ] && chmod 644 test_redirect.php

# Archivos de configuración más restrictivos
echo "- Asegurando archivos sensibles (640)"
[ -f "conf.php" ] && chmod 640 conf.php
[ -f ".env" ] && chmod 640 .env
[ -f "config.php" ] && chmod 640 config.php

# Directorio admin más restrictivo
if [ -d "admin" ]; then
    echo "- Asegurando directorio admin"
    chmod 750 admin
    
    # Archivos PHP del admin
    find admin -type f -name "*.php" -exec chmod 640 {} \;
    
    # Login debe ser accesible
    [ -f "admin/login.php" ] && chmod 644 admin/login.php
    
    # Archivos específicos del admin
    [ -f "admin/panel_simple.php" ] && chmod 640 admin/panel_simple.php
    [ -f "admin/usuarios.php" ] && chmod 640 admin/usuarios.php
    [ -f "admin/stats.php" ] && chmod 640 admin/stats.php
    [ -f "admin/logout.php" ] && chmod 640 admin/logout.php
    [ -f "admin/mapa_simple.php" ] && chmod 640 admin/mapa_simple.php
    [ -f "admin/generar_geo.php" ] && chmod 640 admin/generar_geo.php
    [ -f "admin/ver_coordenadas.php" ] && chmod 640 admin/ver_coordenadas.php
fi

# Si existe directorio de assets
if [ -d "assets" ]; then
    echo "- Configurando directorio assets (755)"
    chmod 755 assets
    find assets -type f \( -name "*.css" -o -name "*.js" -o -name "*.jpg" -o -name "*.png" -o -name "*.gif" \) -exec chmod 644 {} \;
fi

# Si existe directorio de uploads
if [ -d "uploads" ]; then
    echo "- Configurando directorio uploads (775)"
    chmod 775 uploads
    if [[ $modo == "2" ]]; then
        sudo chown -R $WEB_USER:$WEB_GROUP uploads
    fi
fi

# Si existe directorio de logs
if [ -d "logs" ]; then
    echo "- Configurando directorio logs (775)"
    chmod 775 logs
    if [[ $modo == "2" ]]; then
        sudo chown -R $WEB_USER:$WEB_GROUP logs
    fi
fi

# Archivos de script bash ejecutables
echo "- Haciendo scripts ejecutables"
find . -name "*.sh" -type f -exec chmod 755 {} \;

# Proteger .htaccess
if [ -f ".htaccess" ]; then
    echo "- Protegiendo .htaccess (644)"
    chmod 644 .htaccess
fi

# Proteger archivos del repositorio
echo "- Protegiendo archivos del repositorio"
[ -f "README.md" ] && chmod 644 README.md
[ -f ".gitignore" ] && chmod 644 .gitignore
[ -f "composer.json" ] && chmod 644 composer.json
[ -f "composer.lock" ] && chmod 644 composer.lock

# Eliminar permisos de ejecución innecesarios
echo "- Quitando permisos de ejecución innecesarios"
find . -name "*.txt" -o -name "*.md" -o -name "*.json" -o -name "*.xml" -o -name "*.sql" -o -name "*.log" | xargs -r chmod 644

# Archivos temporales o de respaldo
echo "- Configurando archivos temporales"
find . -name "*~" -o -name "*.backup" -o -name "*.bak" | xargs -r chmod 600

echo ""
echo -e "${GREEN}✅ Permisos configurados correctamente${NC}"
echo ""

# Mostrar resumen
echo -e "${BLUE}Resumen de permisos aplicados:${NC}"
echo "┌─────────────────────────────────────────────┐"
echo "│ ARCHIVO/DIRECTORIO     │ PERMISOS          │"
echo "├─────────────────────────────────────────────┤"
echo "│ Directorios           │ 755 (rwxr-xr-x)   │"
echo "│ index.php             │ 644 (rw-r--r--)   │"
echo "│ redirect.php          │ 644 (rw-r--r--)   │"
echo "│ stats.php             │ 644 (rw-r--r--)   │"
echo "│ menu.php              │ 644 (rw-r--r--)   │"
echo "│ conf.php              │ 640 (rw-r-----)   │"
echo "│ admin/                │ 750 (rwxr-x---)   │"
echo "│ admin/*.php           │ 640 (rw-r-----)   │"
echo "│ admin/login.php       │ 644 (rw-r--r--)   │"
echo "│ .htaccess             │ 644 (rw-r--r--)   │"
echo "│ Scripts .sh           │ 755 (rwxr-xr-x)   │"
echo "│ uploads/              │ 775 (rwxrwxr-x)   │"
echo "│ logs/                 │ 775 (rwxrwxr-x)   │"
echo "└─────────────────────────────────────────────┘"

if [[ $modo == "2" ]]; then
    echo ""
    echo -e "${YELLOW}⚠️  Modo producción activado${NC}"
    echo "- Los archivos pertenecen a $WEB_USER:$WEB_GROUP"
    echo "- Para editar archivos usa: sudo nano archivo.php"
    echo "- Para ejecutar scripts usa: sudo ./script.sh"
fi

# Verificación final
echo ""
echo -e "${BLUE}Verificación final de archivos críticos:${NC}"
ls -la index.php redirect.php stats.php conf.php .htaccess 2>/dev/null | grep -E "index|redirect|stats|conf|htaccess"

echo ""
echo -e "${GREEN}Verificando acceso web:${NC}"
echo "1. index.php debe ser accesible"
echo "2. Las URLs cortas deben redirigir correctamente"
echo "3. stats.php debe mostrar estadísticas"
echo "4. El panel admin debe requerir login"

echo ""
echo "🏁 Configuración de permisos completada"
echo ""
echo -e "${GREEN}Próximos pasos:${NC}"
echo "1. Prueba una URL corta existente"
echo "2. Crea una nueva URL y verifica que funcione"
echo "3. Revisa que el panel admin sea accesible"
echo "4. Verifica que conf.php NO sea accesible desde web"

# Script de limpieza opcional
echo ""
echo -e "${YELLOW}¿Deseas ejecutar limpieza de archivos temporales? (s/n)${NC}"
read -p "> " limpieza

if [[ $limpieza == "s" || $limpieza == "S" ]]; then
    echo "Limpiando archivos temporales..."
    find . -name "*~" -type f -delete 2>/dev/null
    find . -name "*.backup" -type f -delete 2>/dev/null
    find . -name "*.bak" -type f -delete 2>/dev/null
    echo "✅ Limpieza completada"
fi

echo ""
echo "¡Todo listo! 🚀"

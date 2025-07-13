#!/bin/bash

echo "🔒 Configurando permisos para URL Shortener..."
echo "=============================================="

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Usuario web (ajustar según tu sistema)
WEB_USER="www-data"
WEB_GROUP="www-data"

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠️  Por favor, ejecuta como root: sudo $0${NC}"
    exit 1
fi

# Cambiar propietario
echo -e "${YELLOW}Cambiando propietario a $WEB_USER:$WEB_GROUP...${NC}"
chown -R $WEB_USER:$WEB_GROUP .

# Permisos para directorios
echo -e "${YELLOW}Configurando permisos de directorios...${NC}"
find . -type d -exec chmod 755 {} \;

# Permisos para archivos
echo -e "${YELLOW}Configurando permisos de archivos...${NC}"
find . -type f -exec chmod 644 {} \;

# Permisos especiales para archivos ejecutables
if [ -f "clean_project.sh" ]; then
    chmod +x clean_project.sh
fi
if [ -f "set_permissions.sh" ]; then
    chmod +x set_permissions.sh
fi

# Proteger archivos sensibles
echo -e "${YELLOW}Protegiendo archivos sensibles...${NC}"
if [ -f "conf.php" ]; then
    chmod 640 conf.php
    echo -e "${GREEN}✓ conf.php protegido${NC}"
fi

# Asegurar .htaccess
if [ -f ".htaccess" ]; then
    chmod 644 .htaccess
    echo -e "${GREEN}✓ .htaccess configurado${NC}"
fi

# Crear directorio de logs si no existe
if [ ! -d "logs" ]; then
    mkdir -p logs
    chmod 775 logs
    echo -e "${GREEN}✓ Directorio logs creado${NC}"
fi

# Verificar permisos
echo -e "\n${GREEN}✅ Permisos configurados correctamente!${NC}"
echo -e "\nVerificación de permisos importantes:"
ls -la conf.php 2>/dev/null || echo "conf.php no encontrado"
ls -la .htaccess 2>/dev/null || echo ".htaccess no encontrado"
ls -ld admin/ 2>/dev/null || echo "admin/ no encontrado"

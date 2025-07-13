# 📋 Guía de Instalación - URL Shortener

## 🚀 Instalación Rápida

### 1. Requisitos del Sistema
- PHP 7.4 o superior
- MySQL 5.7 o superior
- Apache 2.4+ con mod_rewrite O Nginx
- Extensiones PHP: PDO, PDO_MySQL, GD, mbstring

### 2. Instalación Paso a Paso

#### Paso 1: Subir archivos
```bash
# Subir el archivo zip al servidor
unzip url-shortener-*.zip
cd url-shortener
Paso 2: Configurar permisos
bashsudo chmod +x set_permissions.sh
sudo ./set_permissions.sh
Paso 3: Crear base de datos
bashmysql -u root -p < database.sql
Paso 4: Configurar el proyecto
bashcp conf.php.example conf.php
nano conf.php  # Editar con tus datos
Contenido de conf.php:
php<?php
// Configuración de la base de datos
define('DB_HOST', 'localhost');
define('DB_NAME', 'url_shortener');
define('DB_USER', 'tu_usuario');
define('DB_PASS', 'tu_contraseña');

// URL base del sitio (con / al final)
define('BASE_URL', 'https://tu-dominio.com/');

// Configuración de seguridad
define('SECURITY_SALT', 'genera-una-cadena-aleatoria-aqui');
Paso 5: Configurar servidor web
Para Apache:
Crear archivo /etc/apache2/sites-available/url-shortener.conf:
apache<VirtualHost *:80>
    ServerName tu-dominio.com
    DocumentRoot /var/www/url-shortener
    
    <Directory /var/www/url-shortener>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/url-shortener-error.log
    CustomLog ${APACHE_LOG_DIR}/url-shortener-access.log combined
</VirtualHost>
Activar el sitio:
bashsudo a2ensite url-shortener.conf
sudo a2enmod rewrite
sudo systemctl restart apache2
Para Nginx:
Crear archivo /etc/nginx/sites-available/url-shortener:
nginxserver {
    listen 80;
    server_name tu-dominio.com;
    root /var/www/url-shortener;
    index index.php;
    
    location / {
        try_files $uri $uri/ @rewrite;
    }
    
    location @rewrite {
        rewrite ^/([a-zA-Z0-9_-]+)/?$ /redirect.php?code=$1 last;
    }
    
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
    }
    
    location ~ /\.(env|gitignore|htaccess)$ {
        deny all;
    }
    
    location = /conf.php {
        deny all;
    }
}
Activar el sitio:
bashsudo ln -s /etc/nginx/sites-available/url-shortener /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
3. Primer Acceso

Sitio principal: https://tu-dominio.com
Panel admin: https://tu-dominio.com/admin
Usuario: admin
Contraseña: admin123 (¡CAMBIAR INMEDIATAMENTE!)

4. Configuración Post-Instalación
Cambiar contraseña del admin

Acceder al panel admin
Ir a Usuarios
Editar usuario admin
Cambiar contraseña

Configurar SSL/HTTPS con Let's Encrypt
bash# Para Apache
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d tu-dominio.com

# Para Nginx
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d tu-dominio.com
Configurar PHP
Editar /etc/php/7.4/apache2/php.ini o /etc/php/7.4/fpm/php.ini:
iniupload_max_filesize = 10M
post_max_size = 10M
max_execution_time = 300
memory_limit = 256M
Configurar backups automáticos
Crear script /home/usuario/backup-url-shortener.sh:
bash#!/bin/bash
BACKUP_DIR="/home/usuario/backups"
DATE=$(date +%Y%m%d)
mysqldump -u DB_USER -pDB_PASS url_shortener > $BACKUP_DIR/db_$DATE.sql
tar -czf $BACKUP_DIR/files_$DATE.tar.gz /var/www/url-shortener
find $BACKUP_DIR -name "*.sql" -mtime +30 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
Añadir a crontab:
bashcrontab -e
# Añadir:
0 2 * * * /home/usuario/backup-url-shortener.sh
🔧 Solución de Problemas
Error 500

Verificar logs:
bash# Apache
tail -f /var/log/apache2/error.log

# Nginx
tail -f /var/log/nginx/error.log

Verificar permisos: sudo ./set_permissions.sh
Verificar módulos PHP: php -m

URLs no funcionan

Apache: Verificar mod_rewrite
bashsudo a2enmod rewrite
sudo systemctl restart apache2

Verificar .htaccess: Debe existir en la raíz
Verificar AllowOverride: Debe ser "All" en la configuración

Error de base de datos

Verificar conexión:
bashmysql -u tu_usuario -p -h localhost url_shortener

Verificar permisos MySQL:
sqlGRANT ALL PRIVILEGES ON url_shortener.* TO 'tu_usuario'@'localhost';
FLUSH PRIVILEGES;


Página en blanco

Activar errores PHP (temporalmente):
php// Añadir al inicio de index.php
error_reporting(E_ALL);
ini_set('display_errors', 1);


🌐 Configurar Dominios Adicionales
1. Añadir dominio en el panel

Ir a Panel Admin → Dominios
Añadir nuevo dominio

2. Configurar DNS

Añadir registro A apuntando a la IP del servidor

3. Configurar servidor web
Añadir ServerAlias (Apache) o server_name adicional (Nginx)
4. SSL para múltiples dominios
bashsudo certbot --apache -d dominio1.com -d dominio2.com
📊 Optimización
Caché de base de datos
Añadir en MySQL my.cnf:
iniquery_cache_type = 1
query_cache_size = 32M
Índices recomendados
sqlCREATE INDEX idx_short_code ON urls(short_code);
CREATE INDEX idx_clicked_at ON click_stats(clicked_at);
Limpieza periódica
Cron para limpiar estadísticas antiguas:
bash0 3 * * 0 mysql -u user -ppass url_shortener -e "DELETE FROM click_stats WHERE clicked_at < DATE_SUB(NOW(), INTERVAL 90 DAY)"
🔒 Seguridad Adicional
Firewall básico
bashsudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
Fail2ban para SSH
bashsudo apt install fail2ban
sudo systemctl enable fail2ban
Headers de seguridad
Añadir en .htaccess:
apacheHeader set X-Frame-Options "SAMEORIGIN"
Header set X-Content-Type-Options "nosniff"
Header set X-XSS-Protection "1; mode=block"
📞 Soporte

Documentación: https://github.com/tu-usuario/url-shortener
Issues: https://github.com/tu-usuario/url-shortener/issues
Email: soporte@tu-dominio.com


© 2024 URL Shortener - MIT License

Y aquí está el script `create_release.sh` simplificado sin los here-documents problemáticos:

```bash
#!/bin/bash

echo "📦 Creando release de URL Shortener..."
echo "====================================="

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
PROJECT_NAME="url-shortener"
VERSION="1.0"
DATE=$(date +%Y%m%d)
RELEASE_NAME="${PROJECT_NAME}-v${VERSION}-${DATE}"
TEMP_DIR="temp_release_${DATE}"

# Crear directorio temporal
echo -e "${YELLOW}Creando directorio temporal...${NC}"
mkdir -p $TEMP_DIR/$PROJECT_NAME

# Lista de archivos y carpetas a incluir
echo -e "${YELLOW}Copiando archivos del proyecto...${NC}"

# Archivos principales (raíz)
ROOT_FILES=(
    "index.php"
    "redirect.php"
    "stats.php"
    "qr.php"
    "404.php"
    ".htaccess"
    "conf.php.example"
    "README.md"
    "INSTALL.md"
    "set_permissions.sh"
    "database.sql"
    "LICENSE"
)

# Copiar archivos de la raíz
for file in "${ROOT_FILES[@]}"; do
    if [ -f "$file" ]; then
        cp "$file" "$TEMP_DIR/$PROJECT_NAME/"
        echo -e "${GREEN}✓${NC} Copiado: $file"
    else
        echo -e "${RED}✗${NC} No encontrado: $file (crear manualmente si es necesario)"
    fi
done

# Copiar carpeta admin
echo -e "\n${YELLOW}Copiando carpeta admin...${NC}"
mkdir -p "$TEMP_DIR/$PROJECT_NAME/admin"

if [ -d "admin" ]; then
    cp admin/*.php "$TEMP_DIR/$PROJECT_NAME/admin/" 2>/dev/null
    echo -e "${GREEN}✓${NC} Carpeta admin copiada"
else
    echo -e "${RED}✗${NC} Carpeta admin no encontrada"
fi

# Crear el archivo ZIP
echo -e "\n${BLUE}Creando archivo ZIP...${NC}"
cd $TEMP_DIR
zip -r "../${RELEASE_NAME}.zip" $PROJECT_NAME/ -q
cd ..

# Calcular tamaño del archivo
if [ -f "${RELEASE_NAME}.zip" ]; then
    SIZE=$(ls -lh "${RELEASE_NAME}.zip" | awk '{print $5}')
    echo -e "\n${GREEN}✅ Release creado exitosamente!${NC}"
    echo -e "${GREEN}📦 Archivo: ${RELEASE_NAME}.zip${NC}"
    echo -e "${GREEN}📏 Tamaño: ${SIZE}${NC}"
else
    echo -e "\n${RED}❌ Error al crear el archivo ZIP${NC}"
fi

# Limpiar directorio temporal
echo -e "\n${YELLOW}Limpiando archivos temporales...${NC}"
rm -rf $TEMP_DIR

# Crear checksums
if [ -f "${RELEASE_NAME}.zip" ]; then
    echo -e "\n${YELLOW}Generando checksums...${NC}"
    md5sum "${RELEASE_NAME}.zip" > "${RELEASE_NAME}.md5"
    sha256sum "${RELEASE_NAME}.zip" > "${RELEASE_NAME}.sha256"
    echo -e "${GREEN}✓ Checksums generados${NC}"
fi

# Resumen final
echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}✅ RELEASE COMPLETADO${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "Archivos generados:"
echo -e "  - ${BLUE}${RELEASE_NAME}.zip${NC}"
echo -e "  - ${BLUE}${RELEASE_NAME}.md5${NC}"
echo -e "  - ${BLUE}${RELEASE_NAME}.sha256${NC}"
echo -e "\n¡El archivo está listo para distribuir! 🚀"

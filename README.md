# 🔗 URL Shortener - Acortador de URLs

Un sistema completo de acortamiento de URLs con gestión multiusuario, estadísticas detalladas y geolocalización de clicks.

## ✨ Características

- 🔐 **Sistema multiusuario** con roles (admin/usuario)
- 📊 **Panel de administración** completo
- 📈 **Estadísticas detalladas** por URL
- 🗺️ **Geolocalización** de clicks con vista por ciudades
- 📱 **Diseño responsive** 
- 🎨 **Interfaz moderna** y amigable
- 🚀 **URLs cortas personalizables**
- 📋 **Copiar URL** con un click
- 🔒 **Seguro** con contraseñas hasheadas

## 📋 Requisitos del Sistema

### Servidor
- **PHP** 7.4 o superior
- **MySQL** 5.7 o superior / MariaDB 10.3+
- **Apache** 2.4+ con `mod_rewrite` habilitado
- **Extensiones PHP requeridas:**
  - PDO
  - PDO_MySQL
  - JSON
  - Session
  - Filter

### Recomendado
- PHP 8.0+
- MySQL 8.0+
- SSL/HTTPS configurado

## 🚀 Instalación

### 1. Clonar o descargar el proyecto
```bash
git clone https://github.com/tu-usuario/url-shortener.git
cd url-shortener
2. Crear la base de datos
sqlCREATE DATABASE url_shortener CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE url_shortener;
3. Importar las tablas
sql-- Tabla de usuarios
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    status ENUM('active','banned','pending') DEFAULT 'active',
    role ENUM('user','admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    email_verified TINYINT(1) DEFAULT 0,
    verification_token VARCHAR(255) NULL,
    password_reset_token VARCHAR(255) NULL,
    password_reset_expires TIMESTAMP NULL,
    banned_reason TEXT NULL,
    banned_at TIMESTAMP NULL,
    banned_by INT NULL,
    failed_login_attempts INT DEFAULT 0,
    locked_until TIMESTAMP NULL,
    is_active TINYINT(1) DEFAULT 1,
    INDEX idx_status (status),
    INDEX idx_created_at (created_at),
    INDEX idx_verification_token (verification_token),
    INDEX idx_password_reset_token (password_reset_token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de URLs
CREATE TABLE urls (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    short_code VARCHAR(10) NOT NULL UNIQUE,
    original_url TEXT NOT NULL,
    clicks INT DEFAULT 0,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_short_code (short_code),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabla de estadísticas
CREATE TABLE click_stats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    url_id INT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    referer TEXT,
    country VARCHAR(100),
    city VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (url_id) REFERENCES urls(id) ON DELETE CASCADE,
    INDEX idx_url_id (url_id),
    INDEX idx_clicked_at (clicked_at),
    INDEX idx_location (latitude, longitude)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
4. Configurar el archivo conf.php
php<?php
// Configuración de la base de datos
define('DB_HOST', 'localhost');
define('DB_NAME', 'url_shortener');
define('DB_USER', 'tu_usuario');
define('DB_PASS', 'tu_contraseña');

// URL base del sitio (con / al final)
define('BASE_URL', 'http://tudominio.com/');

// Credenciales del administrador principal
define('ADMIN_USERNAME', 'admin');
define('ADMIN_PASSWORD', 'tu_contraseña_segura');
?>
5. Configurar Apache
Para instalación en raíz del dominio:
Asegúrate de que el .htaccess principal tenga:
apacheOptions -Indexes
RewriteEngine On
RewriteBase /

RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule ^([a-zA-Z0-9]+)/?$ index.php?c=$1 [L,QSA]
Para instalación en subdirectorio:
apacheRewriteBase /nombre-subdirectorio/
6. Permisos de archivos
bash# Dar permisos correctos
chmod 644 .htaccess
chmod 644 conf.php
chmod 755 admin/

# Si usas Apache
chown -R www-data:www-data .
🔧 Configuración Post-Instalación
1. Crear el primer usuario admin

Accede a http://tudominio.com/admin/login.php
Usa las credenciales definidas en conf.php
Ve a "Gestión de Usuarios" para crear más usuarios

2. Configurar geolocalización (opcional)
Para habilitar la geolocalización de clicks, puedes usar un servicio como ipapi.co:

El sistema intentará obtener la ubicación automáticamente
No requiere API key para uso básico

3. Configurar HTTPS (recomendado)
apache# Redirigir todo a HTTPS
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}/$1 [R=301,L]
📁 Estructura de Archivos
url-shortener/
├── index.php              # Página principal
├── conf.php              # Configuración
├── stats.php             # Estadísticas públicas
├── menu.php              # Menú de navegación
├── .htaccess             # Reglas de Apache
├── admin/
│   ├── login.php         # Login administrativo
│   ├── logout.php        # Cerrar sesión
│   ├── panel_simple.php  # Panel principal
│   ├── usuarios.php      # Gestión de usuarios
│   ├── mapa_simple.php   # Mapa de ubicaciones
│   └── .htaccess         # Protección del admin
└── README.md             # Este archivo
💻 Uso
Para usuarios:

Regístrate o inicia sesión
Pega tu URL larga en el formulario
Obtén tu URL corta
¡Compártela!

Para administradores:

Accede al panel en /admin/
Gestiona usuarios desde "Gestión Usuarios"
Visualiza estadísticas globales
Explora ubicaciones en el mapa

🛡️ Seguridad

Contraseñas hasheadas con password_hash()
Protección contra SQL injection con PDO
Validación de URLs antes de acortar
Archivos sensibles protegidos con .htaccess
Sesiones seguras para autenticación

🤝 Contribuciones
Las contribuciones son bienvenidas. Por favor:

Fork el proyecto
Crea tu rama de características (git checkout -b feature/AmazingFeature)
Commit tus cambios (git commit -m 'Add some AmazingFeature')
Push a la rama (git push origin feature/AmazingFeature)
Abre un Pull Request

📝 Licencia
Este proyecto está bajo la Licencia MIT - ver el archivo LICENSE para más detalles.
🙏 Agradecimientos

Creado con ❤️ y PHP
Interfaz con Bootstrap
Iconos de Bootstrap Icons
Mapas con Google Maps


¿Necesitas ayuda? Abre un issue en GitHub o contacta al administrador.

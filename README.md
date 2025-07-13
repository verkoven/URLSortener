# 🚀 URL Shortener

Sistema completo de acortador de URLs con panel de administración.

## ✨ Características

- 🔗 Acortador de URLs con códigos personalizados
- 🌐 Soporte para múltiples dominios
- 📊 Estadísticas detalladas de clicks
- 🗺️ Geolocalización de visitantes
- 📱 Generación de códigos QR
- 👥 Sistema de usuarios con roles
- 🎨 Diseño responsive y moderno

## 🛠️ Instalación

### Requisitos
- PHP 7.4 o superior
- MySQL 5.7 o superior
- Apache con mod_rewrite o Nginx
- Extensiones PHP: PDO, PDO_MySQL, GD

### Pasos

1. **Clonar el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/url-shortener.git
   cd url-shortener

Configurar la base de datos
bashmysql -u root -p < database.sql

Configurar el proyecto
bashcp conf.php.example conf.php
# Editar conf.php con tus credenciales

Establecer permisos
bashsudo ./set_permissions.sh

Configurar el servidor web

Para Apache: Asegúrate de que mod_rewrite está activo
Para Nginx: Usa la configuración proporcionada



🔧 Configuración
Apache VirtualHost
apache<VirtualHost *:80>
    ServerName tu-dominio.com
    DocumentRoot /var/www/url-shortener
    
    <Directory /var/www/url-shortener>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
Dominios personalizados

Añade el dominio en el panel admin
Configura el DNS para apuntar al servidor
Añade el VirtualHost correspondiente

📝 Uso
Panel de administración

URL: https://tu-dominio.com/admin
Usuario por defecto: admin
Contraseña: admin123 (¡cambiar inmediatamente!)

API (endpoints básicos)

Crear URL: POST a /api/shorten
Estadísticas: GET a /stats.php?code=CODIGO

🔒 Seguridad

Cambia las credenciales por defecto
Usa HTTPS en producción
Mantén PHP y MySQL actualizados
Realiza backups regulares

📄 Licencia
MIT License - ver archivo LICENSE
👨‍💻 Autor
Tu Nombre - @tu-twitter

⭐ Si te gusta este proyecto, dale una estrella!

## 📦 **database.sql (estructura de la BD):**

```sql
-- URL Shortener Database Structure
-- Version 1.0

CREATE DATABASE IF NOT EXISTS `url_shortener` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `url_shortener`;

-- Tabla de usuarios
CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `role` enum('admin','user') DEFAULT 'user',
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Usuario admin por defecto
INSERT INTO `users` (`username`, `email`, `password`, `role`) VALUES
('admin', 'admin@example.com', '$2y$10$YourHashHere', 'admin');

-- Tabla de dominios personalizados
CREATE TABLE `custom_domains` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `domain` varchar(255) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `status` enum('active','inactive') DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `domain` (`domain`),
  KEY `user_id` (`user_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de URLs
CREATE TABLE `urls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) DEFAULT '1',
  `domain_id` int(11) DEFAULT NULL,
  `short_code` varchar(20) NOT NULL,
  `original_url` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `clicks` int(11) DEFAULT '0',
  `last_clicked` timestamp NULL DEFAULT NULL,
  `active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `short_code` (`short_code`),
  KEY `user_id` (`user_id`),
  KEY `domain_id` (`domain_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`domain_id`) REFERENCES `custom_domains`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabla de estadísticas
CREATE TABLE `click_stats` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url_id` int(11) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text,
  `referer` text,
  `country` varchar(100) DEFAULT NULL,
  `city` varchar(100) DEFAULT NULL,
  `latitude` decimal(10,8) DEFAULT NULL,
  `longitude` decimal(11,8) DEFAULT NULL,
  `clicked_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `url_id` (`url_id`),
  KEY `clicked_at` (`clicked_at`),
  FOREIGN KEY (`url_id`) REFERENCES `urls`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

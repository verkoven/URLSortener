# 🔗 Acortador de URLs

Sistema completo de acortamiento de URLs con panel de administración, estadísticas detalladas y geolocalización de clicks.

## 🚀 Características Principales

### Sistema de Acortamiento
- ✅ Generación automática de URLs cortas con códigos únicos
- ✅ Redirección instantánea a URLs originales
- ✅ Contador de clicks en tiempo real
- ✅ Validación de URLs antes del acortamiento
- ✅ Prevención de duplicados (misma URL = mismo código)

### Panel de Administración
- 🔐 Acceso seguro con autenticación
- 📊 Dashboard con estadísticas generales
- 🔗 Gestión completa de URLs (ver, eliminar)
- 👤 Sistema de sesiones seguras

### Estadísticas y Analytics
- 📈 Estadísticas detalladas por URL
- 🌍 Geolocalización de visitantes
- 📱 Detección de navegadores
- 📅 Filtros temporales (7 días, 30 días, 3 meses, 1 año)
- 🏆 Top 10 URLs más clickeadas
- 🌐 Análisis por países y ciudades

### Visualización de Datos
- 🗺️ Mapa de clicks globales
- 📍 Vista de ubicaciones con enlaces a Google Maps
- 📊 Gráficos de barras para países/ciudades
- 📈 Progreso visual de estadísticas

### Herramientas de Testing
- 🌍 Generador de datos de geolocalización para pruebas
- 📍 Visualizador de coordenadas
- 🔧 Actualización masiva de datos existentes

## 📋 Requisitos del Sistema

- **Servidor Web**: Apache 2.4+ con mod_rewrite
- **PHP**: 7.4 o superior
- **MySQL**: 5.7 o superior
- **Extensiones PHP**: PDO, PDO_MySQL

## 🛠️ Instalación

1. **Clonar o copiar los archivos** al directorio web:
   ```bash
   cd /var/www/html/
   git clone [repository-url] acortador
   ```

2. **Crear la base de datos**:
   ```sql
   CREATE DATABASE url_shortener;
   USE url_shortener;
   ```

3. **Crear las tablas**:
   ```sql
   CREATE TABLE urls (
       id INT AUTO_INCREMENT PRIMARY KEY,
       short_code VARCHAR(10) UNIQUE NOT NULL,
       original_url TEXT NOT NULL,
       clicks INT DEFAULT 0,
       created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       INDEX idx_short_code (short_code)
   );

   CREATE TABLE click_stats (
       id INT AUTO_INCREMENT PRIMARY KEY,
       url_id INT NOT NULL,
       clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
       ip_address VARCHAR(45),
       user_agent TEXT,
       referer TEXT,
       country VARCHAR(100),
       country_code VARCHAR(2),
       city VARCHAR(100),
       region VARCHAR(100),
       latitude DECIMAL(10, 8),
       longitude DECIMAL(11, 8),
       FOREIGN KEY (url_id) REFERENCES urls(id),
       INDEX idx_url_id (url_id),
       INDEX idx_clicked_at (clicked_at)
   );
   ```

4. **Configurar la conexión** en `conf.php`:
   ```php
   define('DB_HOST', 'localhost');
   define('DB_NAME', 'url_shortener');
   define('DB_USER', 'tu_usuario');
   define('DB_PASS', 'tu_contraseña');
   define('BASE_URL', 'http://tudominio.com/acortador/');
   ```

5. **Establecer permisos**:
   ```bash
   sudo chown -R www-data:www-data /var/www/html/acortador
   sudo chmod -R 755 /var/www/html/acortador
   sudo chmod 666 /var/www/html/acortador/log/*.log
   ```

6. **Configurar Apache** (archivo .htaccess incluido):
   - El archivo .htaccess ya está configurado para las redirecciones

## 📁 Estructura de Archivos

```
acortador/
├── index.php              # Página principal del acortador
├── conf.php               # Configuración de la base de datos
├── menu.php               # Menú de navegación
├── stats.php              # Estadísticas públicas de URLs
├── robots.txt             # Configuración para bots
├── favicon.ico            # Icono del sitio
├── README.md              # Este archivo
├── admin/                 # Panel de administración
│   ├── login.php          # Página de login
│   ├── logout.php         # Cerrar sesión
│   ├── panel_simple.php   # Dashboard principal
│   ├── stats.php          # Estadísticas detalladas
│   ├── mapa_simple.php    # Visualización de ubicaciones
│   ├── generar_geo.php    # Generador de datos de prueba
│   └── ver_coordenadas.php # Tabla de coordenadas
└── log/                   # Directorio de logs
    ├── app.log            # Log de la aplicación
    └── test.log           # Log de pruebas
```

## 🔧 Uso

### Para los usuarios:
1. Acceder a `http://tudominio.com/acortador/`
2. Pegar la URL larga en el campo
3. Click en "Acortar URL"
4. Copiar la URL corta generada

### Para administradores:
1. Acceder a `http://tudominio.com/acortador/admin/`
2. Usuario: `admin` / Contraseña: `admin123` (cambiar después del primer login)
3. Desde el panel se puede:
   - Ver estadísticas generales
   - Gestionar URLs
   - Ver mapa de clicks
   - Generar datos de prueba
   - Analizar estadísticas detalladas

## 🔐 Seguridad

- ✅ Validación de todas las entradas de usuario
- ✅ Prepared statements para prevenir SQL injection
- ✅ Sesiones seguras para el panel admin
- ✅ Sanitización de URLs
- ✅ Protección contra XSS
- ✅ Logs de actividad

## 📊 Características Técnicas

- **Código de URL**: 6 caracteres alfanuméricos (más de 56 mil millones de combinaciones)
- **Geolocalización**: Usando ipapi.co (limite: 1000 requests/día gratis)
- **Base de datos**: Índices optimizados para búsquedas rápidas
- **Responsive**: Interfaz adaptable a móviles y tablets
- **Logs**: Sistema de registro para debugging

## 🌟 Funcionalidades Avanzadas

1. **Sistema de Geolocalización**:
   - Detección automática de país y ciudad
   - Almacenamiento de coordenadas GPS
   - Visualización en mapa interactivo

2. **Analytics Detallado**:
   - Clicks por período de tiempo
   - Análisis de navegadores
   - Top países y ciudades
   - URLs más populares

3. **Herramientas de Administración**:
   - Eliminación de URLs
   - Generación de datos de prueba
   - Visualización de coordenadas
   - Exportación de estadísticas

## 🐛 Solución de Problemas

### Las URLs cortas no funcionan:
- Verificar que mod_rewrite está habilitado
- Revisar el archivo .htaccess
- Comprobar la configuración de BASE_URL en conf.php

### No se guardan las geolocalizaciones:
- El servicio gratuito de ipapi.co tiene límite de 1000 requests/día
- Las IPs locales (127.0.0.1) no tienen geolocalización
- Usar el generador de datos de prueba para testing

### Error de permisos:
- Ejecutar el script de permisos o los comandos manuales
- Verificar que el usuario www-data es el propietario

## 📝 Licencia

Este proyecto es de código abierto. Siéntete libre de modificarlo y adaptarlo a tus necesidades.

## 👨‍💻 Créditos

Desarrollado con ❤️ usando PHP, MySQL y JavaScript.

---

**Nota**: Recuerda cambiar las credenciales por defecto del admin y la configuración de la base de datos antes de usar en producción.
```

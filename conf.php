<?php
// conf_simple.php - Configuración simplificada que funciona
// MODIFICA ESTOS VALORES SEGÚN TU SERVIDOR:

define('DB_HOST', 'localhost');        // Tu servidor MySQL
define('DB_NAME', 'url_shortener');    // Nombre de tu base de datos
define('DB_USER', 'r');             // Tu usuario MySQL
define('DB_PASS', '');                 // Tu contraseña MySQL (vacía por defecto)

// URL base de tu acortador (IMPORTANTE: cambiar por tu URL real)
define('BASE_URL', 'http://0ln.eu/acortador/');

// Credenciales de admin
define('ADMIN_USERNAME', 'admin');
define('ADMIN_PASSWORD', 'trapos234');


// Configuración adicional
define('SHORT_URL_LENGTH', 6);
define('SESSION_LIFETIME', 3600); // 1 hora

/**
 * Clase Database simplificada
 */
class Database {
    private static $instance = null;
    private $pdo;
    
    private function __construct() {
        try {
            // Intentar conectar primero sin especificar base de datos
            $pdo_temp = new PDO("mysql:host=" . DB_HOST, DB_USER, DB_PASS);
            $pdo_temp->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            
            // Crear base de datos si no existe
            $pdo_temp->exec("CREATE DATABASE IF NOT EXISTS `" . DB_NAME . "` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
            
            // Conectar a la base de datos específica
            $this->pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
            $this->pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            
            // Crear tablas si no existen
            $this->createTablesIfNeeded();
            
        } catch (PDOException $e) {
            // Log del error para debugging
            error_log("Error de conexión BD: " . $e->getMessage());
            die("Error de conexión a la base de datos. Verifica tu configuración en conf_simple.php");
        }
    }
    
    public static function getInstance() {
        if (self::$instance === null) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    public function getConnection() {
        return $this->pdo;
    }
    
    /**
     * Crear tablas básicas si no existen
     */
    private function createTablesIfNeeded() {
        // Tabla URLs
        $sql_urls = "
        CREATE TABLE IF NOT EXISTS urls (
            id INT AUTO_INCREMENT PRIMARY KEY,
            short_code VARCHAR(10) UNIQUE NOT NULL,
            original_url TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            clicks INT DEFAULT 0,
            last_click TIMESTAMP NULL,
            ip_address VARCHAR(45) NULL,
            user_agent TEXT NULL,
            active TINYINT(1) DEFAULT 1,
            INDEX idx_short_code (short_code),
            INDEX idx_created_at (created_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ";
        
        // Tabla estadísticas de clicks
        $sql_stats = "
        CREATE TABLE IF NOT EXISTS click_stats (
            id INT AUTO_INCREMENT PRIMARY KEY,
            url_id INT,
            clicked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            ip_address VARCHAR(45) NULL,
            user_agent TEXT NULL,
            referer TEXT NULL,
            INDEX idx_url_id (url_id),
            INDEX idx_clicked_at (clicked_at),
            FOREIGN KEY (url_id) REFERENCES urls(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ";
        
        // Tabla sesiones admin
        $sql_sessions = "
        CREATE TABLE IF NOT EXISTS admin_sessions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            session_id VARCHAR(128) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            expires_at TIMESTAMP NOT NULL,
            ip_address VARCHAR(45) NULL,
            INDEX idx_session_id (session_id),
            INDEX idx_expires_at (expires_at)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ";
        
        try {
            $this->pdo->exec($sql_urls);
            $this->pdo->exec($sql_stats);
            $this->pdo->exec($sql_sessions);
            
            // Insertar URL de prueba si la tabla está vacía
            $count = $this->pdo->query("SELECT COUNT(*) FROM urls")->fetchColumn();
            if ($count == 0) {
                $stmt = $this->pdo->prepare("INSERT INTO urls (short_code, original_url, ip_address) VALUES (?, ?, ?)");
                $stmt->execute(['test123', 'https://www.google.com', '127.0.0.1']);
            }
            
        } catch (PDOException $e) {
            error_log("Error creando tablas: " . $e->getMessage());
            // No fallar silenciosamente, seguir funcionando
        }
    }
    
    /**
     * Método para limpiar sesiones expiradas
     */
    public function cleanExpiredSessions() {
        try {
            $this->pdo->exec("DELETE FROM admin_sessions WHERE expires_at < NOW()");
        } catch (PDOException $e) {
            error_log("Error limpiando sesiones: " . $e->getMessage());
        }
    }
}

/**
 * Funciones auxiliares
 */
function generateShortCode($length = SHORT_URL_LENGTH) {
    $characters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    $code = '';
    for ($i = 0; $i < $length; $i++) {
        $code .= $characters[rand(0, strlen($characters) - 1)];
    }
    return $code;
}

function validateUrl($url) {
    return filter_var($url, FILTER_VALIDATE_URL) !== false;
}

function getClientIP() {
    // Obtener IP real del cliente
    $ipKeys = ['HTTP_X_FORWARDED_FOR', 'HTTP_X_REAL_IP', 'HTTP_CLIENT_IP', 'REMOTE_ADDR'];
    
    foreach ($ipKeys as $key) {
        if (!empty($_SERVER[$key])) {
            $ips = explode(',', $_SERVER[$key]);
            $ip = trim($ips[0]);
            
            if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
                return $ip;
            }
        }
    }
    
    return $_SERVER['REMOTE_ADDR'] ?? 'unknown';
}

function sanitizeInput($data) {
    return htmlspecialchars(strip_tags(trim($data)), ENT_QUOTES, 'UTF-8');
}

/**
 * Función para logging de errores
 */
function logError($message, $context = []) {
    $log = date('Y-m-d H:i:s') . " - " . $message;
    if (!empty($context)) {
        $log .= " - Context: " . json_encode($context);
    }
    error_log($log);
}

/**
 * Verificar si la configuración es válida
 */
function checkConfiguration() {
    $errors = [];
    
    if (DB_HOST === 'localhost' && DB_USER === 'root' && DB_PASS === '') {
        // Configuración típica de desarrollo, probablemente está bien
    }
    
    if (strpos(BASE_URL, 'localhost') !== false || strpos(BASE_URL, '127.0.0.1') !== false) {
        // URL de desarrollo, está bien
    } elseif (!filter_var(BASE_URL, FILTER_VALIDATE_URL)) {
        $errors[] = 'BASE_URL no es una URL válida';
    }
    
    return $errors;
}

// Verificar configuración al cargar
$config_errors = checkConfiguration();
if (!empty($config_errors)) {
    foreach ($config_errors as $error) {
        error_log("Error de configuración: " . $error);
    }
}

// Intentar inicializar la base de datos automáticamente
try {
    $db_instance = Database::getInstance();
    // Si llegamos aquí, la conexión fue exitosa
    define('DB_CONNECTION_OK', true);
} catch (Exception $e) {
    define('DB_CONNECTION_OK', false);
    logError("Error inicializando base de datos", ['error' => $e->getMessage()]);
}
?>

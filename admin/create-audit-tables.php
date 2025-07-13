<?php
session_start();
require_once '../conf.php';

if (!isset($_SESSION['admin_logged_in']) || $_SESSION['role'] !== 'admin') {
    die('No autorizado');
}

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Añadir columnas de auditoría a users si no existen
    $db->exec("
        ALTER TABLE users 
        ADD COLUMN IF NOT EXISTS created_by INT NULL,
        ADD COLUMN IF NOT EXISTS modified_by INT NULL,
        ADD COLUMN IF NOT EXISTS modified_at TIMESTAMP NULL
    ");
    
    // Crear tabla de log de actividades
    $db->exec("
        CREATE TABLE IF NOT EXISTS activity_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            action VARCHAR(50) NOT NULL,
            details TEXT,
            ip_address VARCHAR(45),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_user_id (user_id),
            INDEX idx_created_at (created_at)
        )
    ");
    
    echo '<div class="alert alert-success">✅ Tablas de auditoría creadas/actualizadas correctamente</div>';
    
} catch (Exception $e) {
    echo '<div class="alert alert-danger">❌ Error: ' . $e->getMessage() . '</div>';
}
?>

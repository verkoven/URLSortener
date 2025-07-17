<?php
// setup.php - Ejecutar una sola vez para crear tablas
require_once 'config.php';

try {
    // Crear tabla principal
    $sql = "CREATE TABLE IF NOT EXISTS `user_urls` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `user_id` int(11) NOT NULL,
        `url_id` int(11) NOT NULL,
        `title` varchar(255) NOT NULL,
        `category` varchar(50) DEFAULT NULL,
        `favicon` varchar(255) DEFAULT NULL,
        `notes` text,
        `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `user_id` (`user_id`),
        KEY `url_id` (`url_id`),
        KEY `category` (`category`),
        UNIQUE KEY `user_url` (`user_id`, `url_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    $pdo->exec($sql);
    echo "✅ Tabla user_urls creada<br>";
    
    // Crear índices con manejo de errores
    $indices = [
        "CREATE INDEX idx_user_created ON user_urls(user_id, created_at)",
        "CREATE INDEX idx_user_category ON user_urls(user_id, category)", 
        "CREATE INDEX idx_user_url ON user_urls(user_id, url_id)"
    ];
    
    foreach ($indices as $index) {
        try {
            $pdo->exec($index);
            echo "✅ Índice creado: " . substr($index, 13, 20) . "<br>";
        } catch (PDOException $e) {
            if (strpos($e->getMessage(), 'Duplicate key name') !== false) {
                echo "ℹ️ Índice ya existe: " . substr($index, 13, 20) . "<br>";
            } else {
                echo "❌ Error creando índice: " . $e->getMessage() . "<br>";
            }
        }
    }
    
    echo "<br>🎉 <strong>Setup completado!</strong><br>";
    echo "Puedes eliminar este archivo setup.php<br>";
    echo '<a href="index.php">→ Ir al gestor</a>';
    
} catch (PDOException $e) {
    echo "❌ Error: " . $e->getMessage();
}
?>

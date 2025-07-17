<?php
// test_table.php - Verificar si la tabla funciona
require_once 'config.php';

try {
    // Verificar que la tabla existe
    $stmt = $pdo->query("SHOW TABLES LIKE 'user_urls'");
    if ($stmt->rowCount() > 0) {
        echo "✅ Tabla user_urls existe<br>";
        
        // Verificar estructura
        $stmt = $pdo->query("DESCRIBE user_urls");
        $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
        echo "✅ Columnas: " . implode(', ', $columns) . "<br>";
        
        // Test insert
        $stmt = $pdo->prepare("INSERT INTO user_urls (user_id, url_id, title) VALUES (1, 1, 'Test')");
        $stmt->execute();
        echo "✅ Insert funciona<br>";
        
        // Limpiar test
        $pdo->exec("DELETE FROM user_urls WHERE title = 'Test'");
        echo "✅ Delete funciona<br>";
        
        echo "<br>🎉 ¡La tabla funciona perfectamente!<br>";
        echo '<a href="index.php">→ Ir al gestor</a>';
        
    } else {
        echo "❌ Tabla user_urls no existe";
    }
    
} catch (Exception $e) {
    echo "❌ Error: " . $e->getMessage();
}
?>

<?php
// verify_real_user.php - Verificar usuario real de "Chino"
session_start();
require_once '../conf.php';

echo "<h2>🔍 Verificar Usuario Real</h2>";

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Buscar el usuario "Chino" real
    echo "<h3>👤 Buscando usuario 'Chino':</h3>";
    $stmt = $pdo->prepare("SELECT id, username, email, status FROM users WHERE username LIKE '%Chino%' OR email LIKE '%chino%'");
    $stmt->execute();
    $users = $stmt->fetchAll();
    
    if ($users) {
        foreach ($users as $user) {
            echo "<p>• ID: <strong>{$user['id']}</strong> | Username: <strong>{$user['username']}</strong> | Email: <strong>{$user['email']}</strong> | Status: {$user['status']}</p>";
        }
    } else {
        echo "<p>❌ No se encontró usuario 'Chino'</p>";
    }
    
    // Verificar todos los usuarios activos
    echo "<h3>📋 Todos los usuarios activos:</h3>";
    $stmt = $pdo->prepare("SELECT id, username, email, status FROM users WHERE status = 'active' ORDER BY id");
    $stmt->execute();
    $allUsers = $stmt->fetchAll();
    
    foreach ($allUsers as $user) {
        $stmt2 = $pdo->prepare("SELECT COUNT(*) as count FROM urls WHERE user_id = ? AND active = 1");
        $stmt2->execute([$user['id']]);
        $urlCount = $stmt2->fetch()['count'];
        
        echo "<p>• ID: <strong>{$user['id']}</strong> | Username: <strong>{$user['username']}</strong> | Email: <strong>{$user['email']}</strong> | URLs: <strong>{$urlCount}</strong></p>";
    }
    
    // Verificar URLs sin título
    echo "<h3>🔗 URLs sin título (primeras 5):</h3>";
    $stmt = $pdo->prepare("
        SELECT short_code, original_url, title, user_id 
        FROM urls 
        WHERE (title IS NULL OR title = '') AND active = 1 
        ORDER BY created_at DESC 
        LIMIT 5
    ");
    $stmt->execute();
    $emptyTitles = $stmt->fetchAll();
    
    foreach ($emptyTitles as $url) {
        echo "<p>• <strong>{$url['short_code']}</strong> → {$url['original_url']} | User: {$url['user_id']} | Title: '{$url['title']}'</p>";
    }
    
    // Contar URLs sin título
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM urls WHERE (title IS NULL OR title = '') AND active = 1");
    $stmt->execute();
    $emptyCount = $stmt->fetch()['count'];
    echo "<p><strong>Total URLs sin título:</strong> {$emptyCount}</p>";
    
} catch (Exception $e) {
    echo "<p>❌ Error: " . $e->getMessage() . "</p>";
}
?>

<?php
// redirect.php
require_once 'conf.php';

// Obtener el código
$code = isset($_GET['code']) ? $_GET['code'] : '';

if (empty($code)) {
    header('Location: index.php');
    exit();
}

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Buscar la URL
    $stmt = $pdo->prepare("SELECT id, original_url FROM urls WHERE short_code = ? AND active = 1");
    $stmt->execute([$code]);
    $url = $stmt->fetch();
    
    if ($url && !empty($url['original_url'])) {
        // Actualizar clicks
        $stmt = $pdo->prepare("UPDATE urls SET clicks = clicks + 1, last_click = NOW() WHERE id = ?");
        $stmt->execute([$url['id']]);
        
        // Guardar estadísticas básicas
        try {
            $ip = $_SERVER['REMOTE_ADDR'] ?? '';
            $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
            
            $stmt = $pdo->prepare("INSERT INTO click_stats (url_id, ip_address, user_agent, clicked_at) VALUES (?, ?, ?, NOW())");
            $stmt->execute([$url['id'], $ip, $userAgent]);
        } catch (Exception $e) {
            // Ignorar errores de estadísticas
        }
        
        // Redirigir a la URL original
        header('Location: ' . $url['original_url']);
        exit();
    }
} catch (PDOException $e) {
    error_log("Error en redirect.php: " . $e->getMessage());
}

// Si llegamos aquí, redirigir al inicio
header('Location: index.php');
exit();
?>

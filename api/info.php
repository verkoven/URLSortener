<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Obtener el código
$code = $_GET['code'] ?? '';

if (empty($code)) {
    http_response_code(400);
    echo json_encode(['error' => 'No code provided']);
    exit;
}

// Conectar a BD
require_once '../conf.php';

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Buscar URL
    $stmt = $db->prepare("SELECT original_url, clicks, created_at FROM urls WHERE short_code = ? AND active = 1");
    $stmt->execute([$code]);
    $url = $stmt->fetch();
    
    if ($url) {
        $domain = parse_url($url['original_url'], PHP_URL_HOST);
        $favicon = 'https://www.google.com/s2/favicons?domain=' . $domain;
        
        echo json_encode([
            'success' => true,
            'code' => $code,
            'original_url' => $url['original_url'],
            'title' => $domain,
            'favicon' => $favicon,
            'clicks' => $url['clicks'],
            'created_at' => $url['created_at']
        ]);
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'URL not found']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Server error']);
}
?>

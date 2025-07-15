<?php
session_start();
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Credentials: true');

// Para pruebas sin autenticación, comenta estas líneas
if (!isset($_SESSION['user_id'])) {
    // Intentar obtener todas las URLs públicas
    $user_id = null;
} else {
    $user_id = $_SESSION['user_id'];
}

require_once '../conf.php';

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Query según si hay usuario o no
    if ($user_id) {
        $stmt = $db->prepare("
            SELECT u.short_code, u.original_url, u.clicks, u.created_at, cd.domain
            FROM urls u
            LEFT JOIN custom_domains cd ON u.domain_id = cd.id
            WHERE u.user_id = ? AND u.active = 1
            ORDER BY u.created_at DESC
            LIMIT 500
        ");
        $stmt->execute([$user_id]);
    } else {
        // Si no hay sesión, devolver URLs de ejemplo o públicas
        $stmt = $db->query("
            SELECT u.short_code, u.original_url, u.clicks, u.created_at, cd.domain
            FROM urls u
            LEFT JOIN custom_domains cd ON u.domain_id = cd.id
            WHERE u.is_public = 1 AND u.active = 1
            ORDER BY u.created_at DESC
            LIMIT 100
        ");
    }
    
    $urls = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Formatear URLs
    $formatted = array_map(function($url) {
        $domain = $url['domain'] ?? parse_url(BASE_URL, PHP_URL_HOST);
        return [
            'short_code' => $url['short_code'],
            'short_url' => 'https://' . $domain . '/' . $url['short_code'],
            'original_url' => $url['original_url'],
            'clicks' => (int)$url['clicks'],
            'created_at' => $url['created_at'],
            'domain' => $domain
        ];
    }, $urls);
    
    echo json_encode($formatted);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => 'Error del servidor', 'message' => $e->getMessage()]);
}
?>

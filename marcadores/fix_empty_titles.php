<?php
// fix_my_titles_enhanced.php - Títulos con URL destino
require_once 'config.php';
require_once 'functions.php';

$user_id = getCurrentUserId();
$userInfo = getCurrentUserInfo();

echo "<h2>🔧 Títulos Mejorados - {$userInfo['username']}</h2>";

// Obtener URLs sin título
$stmt = $pdo->prepare("
    SELECT id, short_code, original_url, title 
    FROM urls 
    WHERE user_id = ? AND (title IS NULL OR title = '') AND active = 1
");
$stmt->execute([$user_id]);
$urls = $stmt->fetchAll();

$updated = 0;

foreach ($urls as $url) {
    // Generar título mejorado con dominio y URL
    $parsed = parse_url($url['original_url']);
    $domain = str_replace('www.', '', $parsed['host'] ?? 'Enlace');
    
    // Formato: "Dominio - código → URL"
    $enhancedTitle = ucfirst($domain) . ' - ' . $url['short_code'] . ' → ' . $url['original_url'];
    
    $stmt = $pdo->prepare("UPDATE urls SET title = ? WHERE id = ?");
    if ($stmt->execute([$enhancedTitle, $url['id']])) {
        echo "<p>✅ <strong>{$url['short_code']}</strong> → '{$enhancedTitle}'</p>";
        $updated++;
    }
}

echo "<h3>🎉 {$updated} títulos mejorados con URL destino</h3>";
echo "<p><a href='index.php'>← Volver al gestor</a></p>";
?>

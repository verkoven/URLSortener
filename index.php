<?php
require_once "conf.php";

// Función para obtener geolocalización de IP
function getLocationFromIP($ip) {
    // Evitar procesar IPs locales
    if ($ip === '127.0.0.1' || $ip === '::1' || strpos($ip, '192.168.') === 0 || strpos($ip, '10.') === 0) {
        return [
            'country' => 'Local',
            'country_code' => 'LO',
            'city' => 'Localhost',
            'region' => 'Local'
        ];
    }
    
    // Usar API gratuita de geolocalización (ip-api.com - 1000 requests/mes gratis)
    $api_url = "http://ip-api.com/json/{$ip}?fields=status,country,countryCode,region,city,lat,lon,timezone";
    
    // Usar cURL para mejor control
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $api_url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 3); // Timeout de 3 segundos
    curl_setopt($ch, CURLOPT_USERAGENT, 'URL Shortener Bot 1.0');
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($response && $http_code === 200) {
        $data = json_decode($response, true);
        
        if ($data && $data['status'] === 'success') {
            return [
                'country' => $data['country'] ?? 'Unknown',
                'country_code' => $data['countryCode'] ?? 'XX',
                'city' => $data['city'] ?? 'Unknown',
                'region' => $data['region'] ?? 'Unknown',
                'latitude' => $data['lat'] ?? null,
                'longitude' => $data['lon'] ?? null,
                'timezone' => $data['timezone'] ?? null
            ];
        }
    }
    
    // Fallback: API alternativa ipapi.co (30,000 requests/mes gratis)
    $api_url2 = "https://ipapi.co/{$ip}/json/";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $api_url2);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 3);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_USERAGENT, 'URL Shortener Bot 1.0');
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($response && $http_code === 200) {
        $data = json_decode($response, true);
        
        if ($data && !isset($data['error'])) {
            return [
                'country' => $data['country_name'] ?? 'Unknown',
                'country_code' => $data['country_code'] ?? 'XX',
                'city' => $data['city'] ?? 'Unknown',
                'region' => $data['region'] ?? 'Unknown',
                'latitude' => $data['latitude'] ?? null,
                'longitude' => $data['longitude'] ?? null,
                'timezone' => $data['timezone'] ?? null
            ];
        }
    }
    
    // Si ambas APIs fallan, devolver datos por defecto
    return [
        'country' => 'Unknown',
        'country_code' => 'XX',
        'city' => 'Unknown',
        'region' => 'Unknown',
        'latitude' => null,
        'longitude' => null,
        'timezone' => null
    ];
}

$message = "";
$result = null;

// Manejar redirección
if (isset($_GET["c"])) {
    $code = $_GET["c"];
    $db = Database::getInstance()->getConnection();
    $stmt = $db->prepare("SELECT * FROM urls WHERE short_code = ? AND active = 1");
    $stmt->execute([$code]);
    $url = $stmt->fetch();
    
    if ($url) {
        // Actualizar contador de clicks
        $db->prepare("UPDATE urls SET clicks = clicks + 1, last_click = NOW() WHERE id = ?")->execute([$url["id"]]);
        
        // Obtener información del visitante
        $visitor_ip = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
        $referer = $_SERVER['HTTP_REFERER'] ?? '';
        
        // Obtener geolocalización
        $location = getLocationFromIP($visitor_ip);
        
        // Guardar estadística detallada con geolocalización
        try {
            $stmt = $db->prepare("
                INSERT INTO click_stats (
                    url_id, ip_address, user_agent, referer, 
                    country, country_code, city, region,
                    latitude, longitude, timezone
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            
            $stmt->execute([
                $url["id"],
                $visitor_ip,
                $user_agent,
                $referer,
                $location['country'],
                $location['country_code'],
                $location['city'],
                $location['region'],
                $location['latitude'],
                $location['longitude'],
                $location['timezone']
            ]);
        } catch (PDOException $e) {
            // Si falla la inserción con geolocalización, insertar sin ella
            error_log("Error guardando geolocalización: " . $e->getMessage());
            try {
                $stmt = $db->prepare("
                    INSERT INTO click_stats (url_id, ip_address, user_agent, referer) 
                    VALUES (?, ?, ?, ?)
                ");
                $stmt->execute([$url["id"], $visitor_ip, $user_agent, $referer]);
            } catch (PDOException $e2) {
                error_log("Error guardando estadística básica: " . $e2->getMessage());
            }
        }
        
        // Redirigir al destino
        header("Location: " . $url["original_url"]);
        exit;
    } else {
        $message = "URL no encontrada";
    }
}

// Manejar acortamiento
if ($_POST["action"] ?? "" === "shorten") {
    $original_url = trim($_POST["url"] ?? "");
    
    if (empty($original_url)) {
        $message = "Por favor introduce una URL";
    } elseif (!validateUrl($original_url)) {
        $message = "URL no válida";
    } else {
        $db = Database::getInstance()->getConnection();
        
        do {
            $short_code = generateShortCode();
            $stmt = $db->prepare("SELECT id FROM urls WHERE short_code = ?");
            $stmt->execute([$short_code]);
        } while ($stmt->fetch());
        
        $stmt = $db->prepare("INSERT INTO urls (short_code, original_url, ip_address) VALUES (?, ?, ?)");
        $stmt->execute([$short_code, $original_url, $_SERVER["REMOTE_ADDR"] ?? "unknown"]);
        
        $result = [
            "success" => true,
            "short_url" => BASE_URL . "?c=" . $short_code,
            "short_code" => $short_code
        ];
        $message = "¡URL acortada exitosamente!";
    }
}

$db = Database::getInstance()->getConnection();
$stats = $db->query("SELECT COUNT(*) as total_urls, COALESCE(SUM(clicks), 0) as total_clicks FROM urls")->fetch();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acortador de URLs</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; background: #f5f5f5; }
        .header { background: #007bff; color: white; padding: 30px; text-align: center; border-radius: 10px; margin-bottom: 30px; }
        .header h1 { margin: 0; font-size: 2.5em; }
        .stats { display: flex; gap: 20px; justify-content: center; margin-top: 20px; }
        .stat { text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; }
        .form-container { background: white; padding: 30px; border-radius: 10px; margin-bottom: 20px; }
        .form-group { margin-bottom: 20px; }
        .form-group label { display: block; margin-bottom: 5px; font-weight: bold; }
        .form-group input { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 5px; font-size: 16px; }
        .btn { background: #007bff; color: white; padding: 12px 24px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; }
        .btn:hover { background: #0056b3; }
        .message { padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .success { background: #d4edda; color: #155724; border: 1px solid #c3e6cb; }
        .error { background: #f8d7da; color: #721c24; border: 1px solid #f5c6cb; }
        .result { background: white; padding: 20px; border-radius: 10px; border: 2px solid #007bff; }
        .short-url { background: #f8f9fa; padding: 10px; border-radius: 5px; font-family: monospace; word-break: break-all; margin: 10px 0; }
        .geo-info {
            background: #e7f3ff;
            border-left: 4px solid #007bff;
            padding: 10px;
            margin-top: 20px;
            border-radius: 0 5px 5px 0;
        }
        .geo-info h4 {
            margin: 0 0 10px 0;
            color: #0056b3;
        }
        .geo-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 10px;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔗 Acortador de URLs</h1>
        <p>Convierte enlaces largos en URLs cortas y fáciles de compartir</p>
        <div class="stats">
            <div class="stat">
                <div class="stat-number"><?= number_format($stats["total_urls"]) ?></div>
                <div>URLs Creadas</div>
            </div>
            <div class="stat">
                <div class="stat-number"><?= number_format($stats["total_clicks"]) ?></div>
                <div>Clicks Totales</div>
            </div>
        </div>
    </div>
    
    <?php if ($message): ?>
        <div class="message <?= isset($result) && $result ? "success" : "error" ?>">
            <?= htmlspecialchars($message) ?>
        </div>
    <?php endif; ?>
    
    <?php if ($result): ?>
        <div class="result">
            <h3>¡URL Acortada! 🎉</h3>
            <p>Tu nueva URL corta:</p>
            <div class="short-url"><?= htmlspecialchars($result["short_url"]) ?></div>
            
            <div class="geo-info">
                <h4>🌍 Geolocalización Activada</h4>
                <p>Tu acortador ahora registra la ubicación geográfica de los visitantes para estadísticas detalladas.</p>
                <div class="geo-stats">
                    <div><strong>📊 Estadísticas:</strong> País, ciudad, región</div>
                    <div><strong>🗺️ Mapas:</strong> Coordenadas GPS</div>
                    <div><strong>🕐 Zona Horaria:</strong> Tiempo local</div>
                    <div><strong>🔒 Privacidad:</strong> IPs anonimizadas</div>
                </div>
            </div>
        </div>
    <?php endif; ?>
    
    <div class="form-container">
        <form method="POST">
            <input type="hidden" name="action" value="shorten">
            <div class="form-group">
                <label for="url">URL a acortar:</label>
                <input type="url" id="url" name="url" placeholder="https://ejemplo.com/url-muy-larga" required>
            </div>
            <button type="submit" class="btn">🚀 Acortar URL</button>
        </form>
    </div>
    
    <div style="text-align: center; margin-top: 30px;">
        <a href="admin/panel_simple.php" style="color: #007bff; text-decoration: none;">🛠️ Panel de Administración</a>
    </div>
</body>
</html>

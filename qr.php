<?php
require_once 'conf.php';

// Obtener el código de la URL
$code = isset($_GET['code']) ? trim($_GET['code']) : '';

if (empty($code)) {
    die('Error: No se especificó código');
}

try {
    // Conexión a la base de datos
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Buscar la URL
    $stmt = $db->prepare("
        SELECT u.*, cd.domain as custom_domain 
        FROM urls u 
        LEFT JOIN custom_domains cd ON u.domain_id = cd.id 
        WHERE u.short_code = ? AND u.active = 1
    ");
    $stmt->execute([$code]);
    $url = $stmt->fetch();
    
    if (!$url) {
        die('Error: URL no encontrada');
    }
    
    // Determinar la URL completa
    if (!empty($url['custom_domain'])) {
        $short_url = "https://" . $url['custom_domain'] . "/" . $url['short_code'];
    } else {
        $short_url = rtrim(BASE_URL, '/') . '/' . $url['short_code'];
    }
    
} catch (Exception $e) {
    die('Error de base de datos');
}

// Configuración del QR
$size = isset($_GET['size']) ? intval($_GET['size']) : 300;
$size = max(100, min(1000, $size)); // Entre 100 y 1000

// Método de API a usar
$api_method = isset($_GET['api']) ? $_GET['api'] : 'qrserver';

// URLs de diferentes APIs
$qr_apis = [
    'qrserver' => 'https://api.qrserver.com/v1/create-qr-code/?size=' . $size . 'x' . $size . '&data=' . urlencode($short_url),
    'google' => 'https://chart.googleapis.com/chart?chs=' . $size . 'x' . $size . '&cht=qr&chl=' . urlencode($short_url) . '&choe=UTF-8&chld=M|0',
    'quickchart' => 'https://quickchart.io/qr?text=' . urlencode($short_url) . '&size=' . $size,
    'goqr' => 'https://api.qr-code-generator.com/v1/create?access-token=demo&size=' . $size . '&data=' . urlencode($short_url)
];

// Usar la API seleccionada
$qr_url = $qr_apis[$api_method] ?? $qr_apis['qrserver'];

// Si se solicita solo la imagen
if (!isset($_GET['view'])) {
    header('Location: ' . $qr_url);
    exit;
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Código QR - <?php echo htmlspecialchars($code); ?></title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
            padding: 20px;
        }
        .qr-container {
            background: white;
            border-radius: 20px;
            padding: 40px;
            box-shadow: 0 20px 60px rgba(0,0,0,0.15);
            text-align: center;
            max-width: 500px;
            width: 100%;
        }
        h1 {
            color: #2c3e50;
            margin-bottom: 10px;
            font-size: 2em;
        }
        .url-info {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 10px;
            margin: 20px 0;
            word-break: break-all;
        }
        .short-url {
            color: #667eea;
            font-weight: bold;
            font-size: 1.1em;
        }
        .qr-code {
            margin: 30px 0;
            padding: 20px;
            background: white;
            border: 1px solid #e9ecef;
            border-radius: 15px;
            display: inline-block;
            position: relative;
            min-height: <?php echo $size; ?>px;
            min-width: <?php echo $size; ?>px;
        }
        .qr-code img {
            display: block;
            max-width: 100%;
            height: auto;
        }
        .qr-loading {
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            display: none;
        }
        .qr-error {
            display: none;
            color: #dc3545;
            margin: 20px 0;
        }
        .buttons {
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
            margin-top: 30px;
        }
        .btn {
            padding: 12px 25px;
            border-radius: 8px;
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s;
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        .btn-primary {
            background: #667eea;
            color: white;
        }
        .btn-primary:hover {
            background: #5a67d8;
            transform: translateY(-2px);
        }
        .btn-secondary {
            background: #6c757d;
            color: white;
        }
        .btn-secondary:hover {
            background: #5a6268;
            transform: translateY(-2px);
        }
        .download-sizes {
            margin-top: 20px;
        }
        .size-btn {
            padding: 8px 15px;
            margin: 5px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            border-radius: 5px;
            text-decoration: none;
            display: inline-block;
            transition: all 0.3s;
        }
        .size-btn:hover {
            background: #667eea;
            color: white;
        }
        .api-selector {
            margin: 10px 0;
            font-size: 0.9em;
        }
        .api-selector a {
            color: #667eea;
            text-decoration: none;
            margin: 0 5px;
        }
        .api-selector a:hover {
            text-decoration: underline;
        }
        .spinner {
            border: 3px solid #f3f3f3;
            border-top: 3px solid #667eea;
            border-radius: 50%;
            width: 40px;
            height: 40px;
            animation: spin 1s linear infinite;
        }
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
    </style>
</head>
<body>
    <div class="qr-container">
        <h1>📱 Código QR</h1>
        
        <div class="url-info">
            <p>URL corta:</p>
            <p class="short-url"><?php echo htmlspecialchars($short_url); ?></p>
        </div>
        
        <div class="qr-code" id="qr-container">
            <div class="qr-loading" id="loading">
                <div class="spinner"></div>
                <p>Generando QR...</p>
            </div>
            <img id="qr-image" 
                 src="<?php echo $qr_url; ?>" 
                 alt="Código QR"
                 onload="qrLoaded()"
                 onerror="qrError()">
        </div>
        
        <div class="qr-error" id="error-msg">
            ⚠️ Error al cargar el QR. Prueba con otra API:
        </div>
        
        <div class="api-selector">
            <small>Cambiar API: 
                <a href="?code=<?php echo $code; ?>&view=1&api=qrserver">QR Server</a> |
                <a href="?code=<?php echo $code; ?>&view=1&api=google">Google</a> |
                <a href="?code=<?php echo $code; ?>&view=1&api=quickchart">QuickChart</a>
            </small>
        </div>
        
        <div class="download-sizes">
            <p>Descargar en diferentes tamaños:</p>
            <a href="?code=<?php echo urlencode($code); ?>&size=200&api=<?php echo $api_method; ?>" class="size-btn" download>200px</a>
            <a href="?code=<?php echo urlencode($code); ?>&size=300&api=<?php echo $api_method; ?>" class="size-btn" download>300px</a>
            <a href="?code=<?php echo urlencode($code); ?>&size=500&api=<?php echo $api_method; ?>" class="size-btn" download>500px</a>
            <a href="?code=<?php echo urlencode($code); ?>&size=1000&api=<?php echo $api_method; ?>" class="size-btn" download>1000px</a>
        </div>
        
        <div class="buttons">
            <a href="<?php echo $qr_url; ?>" download="qr-<?php echo $code; ?>.png" class="btn btn-primary" id="download-btn">
                💾 Descargar QR
            </a>
            <a href="/" class="btn btn-secondary">
                🏠 Volver al inicio
            </a>
        </div>
        
        <!-- Canvas oculto para generar QR localmente si todas las APIs fallan -->
        <canvas id="qr-canvas" style="display: none;"></canvas>
    </div>
    
    <script>
        let qrLoaded = false;
        
        // Mostrar spinner mientras carga
        document.getElementById('loading').style.display = 'block';
        
        function qrLoaded() {
            document.getElementById('loading').style.display = 'none';
            qrLoaded = true;
        }
        
        function qrError() {
            document.getElementById('loading').style.display = 'none';
            document.getElementById('error-msg').style.display = 'block';
            
            // Intentar con otra API automáticamente
            tryAlternativeAPI();
        }
        
        function tryAlternativeAPI() {
            const currentAPI = '<?php echo $api_method; ?>';
            const apis = ['qrserver', 'google', 'quickchart'];
            
            // Encontrar la siguiente API disponible
            let nextAPI = '';
            for (let i = 0; i < apis.length; i++) {
                if (apis[i] !== currentAPI) {
                    nextAPI = apis[i];
                    break;
                }
            }
            
            if (nextAPI && !qrLoaded) {
                // Cambiar la fuente de la imagen
                const newUrl = '?code=<?php echo $code; ?>&view=1&api=' + nextAPI;
                setTimeout(() => {
                    if (!qrLoaded) {
                        window.location.href = newUrl;
                    }
                }, 2000);
            }
        }
        
        // Verificar si la imagen se carga después de 5 segundos
        setTimeout(() => {
            if (!qrLoaded) {
                qrError();
            }
        }, 5000);
    </script>
</body>
</html>

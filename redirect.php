<?php
require_once 'conf.php';

// Obtener el código
$code = isset($_GET['code']) ? trim($_GET['code']) : '';

if (empty($code)) {
    header('Location: /');
    exit;
}

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Buscar la URL por código - SIMPLE, sin verificación de dominio
    $stmt = $db->prepare("SELECT * FROM urls WHERE short_code = ? AND active = 1");
    $stmt->execute([$code]);
    $url = $stmt->fetch();
    
    if ($url) {
        // Registrar el click
        $ip = $_SERVER['REMOTE_ADDR'] ?? '';
        $user_agent = $_SERVER['HTTP_USER_AGENT'] ?? '';
        $referer = $_SERVER['HTTP_REFERER'] ?? '';
        
        try {
            $stmt = $db->prepare("
                INSERT INTO click_stats (url_id, ip_address, user_agent, referer, clicked_at) 
                VALUES (?, ?, ?, ?, NOW())
            ");
            $stmt->execute([$url['id'], $ip, $user_agent, $referer]);
            
            // Incrementar contador
            $stmt = $db->prepare("UPDATE urls SET clicks = clicks + 1 WHERE id = ?");
            $stmt->execute([$url['id']]);
        } catch (Exception $e) {
            // Si falla el registro de stats, continuar con la redirección
        }
        
        // REDIRIGIR - Esto es lo importante
        header('HTTP/1.1 301 Moved Permanently');
        header('Location: ' . $url['original_url']);
        exit();
    }
} catch (Exception $e) {
    // Error de base de datos
}

// Si llegamos aquí, mostrar 404
header('HTTP/1.0 404 Not Found');
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - URL no encontrada</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            margin: 0;
            color: white;
        }
        .error-container {
            text-align: center;
            padding: 40px;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
        }
        .error-code {
            font-size: 8em;
            font-weight: bold;
            margin: 0;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.3);
        }
        .error-message {
            font-size: 1.5em;
            margin: 20px 0;
            opacity: 0.9;
        }
        .btn-home {
            display: inline-block;
            padding: 15px 30px;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 30px;
            font-weight: 600;
            transition: all 0.3s;
            margin-top: 20px;
        }
        .btn-home:hover {
            transform: translateY(-2px);
            box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
        }
    </style>
</head>
<body>
    <div class="error-container">
        <h1 class="error-code">404</h1>
        <p class="error-message">¡Oops! URL no encontrada</p>
        <p>El código <strong><?php echo htmlspecialchars($code); ?></strong> no existe o ha sido desactivado.</p>
        <a href="/" class="btn-home">Volver al inicio</a>
    </div>
</body>
</html>

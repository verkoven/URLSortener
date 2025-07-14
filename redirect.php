<?php
require_once 'conf.php';

// Obtener el código corto de la URL
$request_uri = $_SERVER['REQUEST_URI'];
$short_code = trim($request_uri, '/');

// Si no hay código, redirigir al index
if (empty($short_code)) {
    header('Location: index.php');
    exit();
}

// Conectar a la base de datos
try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Error de conexión");
}

// NUEVA VERIFICACIÓN: Obtener el dominio desde el que se está accediendo
$current_domain = $_SERVER['HTTP_HOST'];
$main_domain = parse_url(BASE_URL, PHP_URL_HOST);

// Buscar la URL con información del dominio asignado
$stmt = $pdo->prepare("
    SELECT u.*, cd.domain as assigned_domain, cd.user_id as domain_owner
    FROM urls u 
    LEFT JOIN custom_domains cd ON u.domain_id = cd.id
    WHERE u.short_code = ? AND u.active = 1
");
$stmt->execute([$short_code]);
$url = $stmt->fetch();

if ($url) {
    // VERIFICACIÓN DE DOMINIO
    $can_redirect = false;
    
    // Si la URL tiene un dominio asignado
    if ($url['domain_id'] && $url['assigned_domain']) {
        // Solo permitir redirección desde el dominio asignado
        if ($current_domain === $url['assigned_domain']) {
            $can_redirect = true;
        }
    } else {
        // Si no tiene dominio asignado, solo funciona desde el dominio principal
        if ($current_domain === $main_domain) {
            $can_redirect = true;
        }
    }
    
    // Verificar si puede redirigir
    if (!$can_redirect) {
        // Mostrar error o redirigir al dominio correcto
        ?>
        <!DOCTYPE html>
        <html lang="es">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Dominio Incorrecto</title>
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                    background: #f5f5f5;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100vh;
                    margin: 0;
                }
                .error-box {
                    background: white;
                    padding: 40px;
                    border-radius: 10px;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                    text-align: center;
                    max-width: 500px;
                }
                .error-icon {
                    font-size: 4em;
                    margin-bottom: 20px;
                }
                h1 {
                    color: #333;
                    margin-bottom: 20px;
                }
                p {
                    color: #666;
                    line-height: 1.6;
                    margin-bottom: 30px;
                }
                .btn {
                    display: inline-block;
                    padding: 12px 30px;
                    background: #667eea;
                    color: white;
                    text-decoration: none;
                    border-radius: 5px;
                    transition: background 0.3s;
                }
                .btn:hover {
                    background: #5a67d8;
                }
                .correct-url {
                    background: #f8f9fa;
                    padding: 10px;
                    border-radius: 5px;
                    margin: 20px 0;
                    font-family: monospace;
                    word-break: break-all;
                }
            </style>
        </head>
        <body>
            <div class="error-box">
                <div class="error-icon">🚫</div>
                <h1>Dominio Incorrecto</h1>
                <p>Esta URL corta no está disponible en este dominio.</p>
                
                <?php if ($url['assigned_domain']): ?>
                    <p>Esta URL solo funciona desde:</p>
                    <div class="correct-url">
                        https://<?php echo htmlspecialchars($url['assigned_domain']); ?>/<?php echo htmlspecialchars($short_code); ?>
                    </div>
                    <a href="https://<?php echo htmlspecialchars($url['assigned_domain']); ?>/<?php echo htmlspecialchars($short_code); ?>" class="btn">
                        Ir al dominio correcto
                    </a>
                <?php else: ?>
                    <p>Esta URL solo funciona desde el dominio principal:</p>
                    <div class="correct-url">
                        <?php echo rtrim(BASE_URL, '/'); ?>/<?php echo htmlspecialchars($short_code); ?>
                    </div>
                    <a href="<?php echo rtrim(BASE_URL, '/'); ?>/<?php echo htmlspecialchars($short_code); ?>" class="btn">
                        Ir al dominio principal
                    </a>
                <?php endif; ?>
            </div>
        </body>
        </html>
        <?php
        exit();
    }
    
    // Si llegamos aquí, el dominio es correcto, proceder con la redirección
    
    // Incrementar contador de clicks
    $stmt = $pdo->prepare("UPDATE urls SET clicks = clicks + 1 WHERE id = ?");
    $stmt->execute([$url['id']]);
    
    // Registrar estadísticas detalladas
    try {
        $stmt = $pdo->prepare("
            INSERT INTO click_stats (url_id, clicked_at, ip_address, user_agent, referer) 
            VALUES (?, NOW(), ?, ?, ?)
        ");
        $stmt->execute([
            $url['id'],
            $_SERVER['REMOTE_ADDR'] ?? '',
            $_SERVER['HTTP_USER_AGENT'] ?? '',
            $_SERVER['HTTP_REFERER'] ?? ''
        ]);
    } catch (Exception $e) {
        // Si falla el registro de stats, continuar con la redirección
    }
    
    // Redirigir a la URL original
    header('Location: ' . $url['original_url']);
    exit();
    
} else {
    // URL no encontrada
    header('HTTP/1.0 404 Not Found');
    include '404.php';
    exit();
}
?>

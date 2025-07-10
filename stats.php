<?php
require_once 'conf.php';

// Verificar que se proporcione un código
if (!isset($_GET['code']) || empty($_GET['code'])) {
    die('No se proporcionó código de URL');
}

$code = $_GET['code'];

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener información de la URL
    $stmt = $pdo->prepare("SELECT * FROM urls WHERE short_code = ?");
    $stmt->execute([$code]);
    $url = $stmt->fetch();
    
    if (!$url) {
        die('URL no encontrada');
    }
    
    // Obtener estadísticas
    $stmt = $pdo->prepare("SELECT COUNT(*) as total_clicks FROM click_stats WHERE url_id = ?");
    $stmt->execute([$url['id']]);
    $stats = $stmt->fetch();
    
} catch (PDOException $e) {
    die("Error: " . $e->getMessage());
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Estadísticas - <?php echo $code; ?></title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <h1>📊 Estadísticas de URL</h1>
        
        <div class="card mt-4">
            <div class="card-body">
                <h5>URL Corta:</h5>
                <p><a href="<?php echo BASE_URL . $code; ?>"><?php echo BASE_URL . $code; ?></a></p>
                
                <h5>URL Original:</h5>
                <p><a href="<?php echo htmlspecialchars($url['original_url']); ?>" target="_blank">
                    <?php echo htmlspecialchars($url['original_url']); ?>
                </a></p>
                
                <h5>Total de Clicks:</h5>
                <p class="h3"><?php echo number_format($stats['total_clicks']); ?></p>
                
                <h5>Creada:</h5>
                <p><?php echo date('d/m/Y H:i', strtotime($url['created_at'])); ?></p>
            </div>
        </div>
        
        <div class="mt-3">
            <a href="index.php" class="btn btn-primary">Volver al inicio</a>
        </div>
    </div>
</body>
</html>

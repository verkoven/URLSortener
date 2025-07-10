<?php
session_start(); // AÑADIDO para manejar usuarios logueados
require_once 'conf.php';

// Conectar a la base de datos
try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Error de conexión: " . $e->getMessage());
}

$message = '';
$messageType = '';
$shortUrl = '';

// Procesar el formulario
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['url'])) {
    $url = trim($_POST['url']);
    
    // Validar URL
    if (empty($url)) {
        $message = 'Por favor, introduce una URL';
        $messageType = 'danger';
    } elseif (!filter_var($url, FILTER_VALIDATE_URL)) {
        $message = 'Por favor, introduce una URL válida';
        $messageType = 'danger';
    } else {
        try {
            // Verificar si la URL ya existe
            $stmt = $pdo->prepare("SELECT short_code FROM urls WHERE original_url = ?");
            $stmt->execute([$url]);
            $existing = $stmt->fetch();
            
            if ($existing) {
                // URL ya existe, devolver el código existente
                $shortCode = $existing['short_code'];
                $message = 'Esta URL ya fue acortada anteriormente';
                $messageType = 'info';
            } else {
                // Generar nuevo código único
                do {
                    $shortCode = generateShortCode();
                    $stmt = $pdo->prepare("SELECT COUNT(*) FROM urls WHERE short_code = ?");
                    $stmt->execute([$shortCode]);
                    $exists = $stmt->fetchColumn();
                } while ($exists > 0);
                
                // MODIFICADO: Obtener el ID del usuario si está logueado
                $user_id = isset($_SESSION['user_id']) ? $_SESSION['user_id'] : null;
                
                // MODIFICADO: Insertar nueva URL con user_id
                $stmt = $pdo->prepare("INSERT INTO urls (short_code, original_url, user_id, created_at) VALUES (?, ?, ?, NOW())");
                $stmt->execute([$shortCode, $url, $user_id]);
                
                $message = '¡URL acortada con éxito!';
                $messageType = 'success';
            }
            
            $shortUrl = BASE_URL . $shortCode;
            
        } catch (PDOException $e) {
            $message = 'Error al procesar la URL';
            $messageType = 'danger';
            error_log($e->getMessage());
        }
    }
}

// Obtener estadísticas generales
$totalUrls = $pdo->query("SELECT COUNT(*) FROM urls")->fetchColumn();
$totalClicks = $pdo->query("SELECT SUM(clicks) FROM urls")->fetchColumn() ?: 0;
?>

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acortador de URLs</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.7.2/font/bootstrap-icons.css">
    <style>
        body {
            background-color: #f8f9fa;
        }
        .main-container {
            margin-top: 50px;
        }
        .url-result {
            background-color: #e9ecef;
            padding: 15px;
            border-radius: 5px;
            margin-top: 20px;
        }
        .stats-box {
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        .feature-icon {
            font-size: 2rem;
            color: #0d6efd;
        }
    </style>
</head>
<body>
    <?php include 'menu.php'; ?>

    <div class="container main-container">
        <div class="row">
            <div class="col-md-8 mx-auto">
                <div class="text-center mb-5">
                    <h1 class="display-4">
                        <i class="bi bi-link-45deg"></i> Acortador de URLs
                    </h1>
                    <p class="lead">Convierte tus URLs largas en enlaces cortos y fáciles de compartir</p>
                </div>

                <!-- Formulario -->
                <div class="card shadow">
                    <div class="card-body p-4">
                        <form method="POST" action="">
                            <div class="input-group mb-3">
                                <span class="input-group-text">
                                    <i class="bi bi-link"></i>
                                </span>
                                <input type="url" class="form-control form-control-lg" name="url" 
                                       placeholder="Pega tu URL larga aquí..." 
                                       value="<?php echo isset($_POST['url']) ? htmlspecialchars($_POST['url']) : ''; ?>"
                                       required>
                                <button class="btn btn-primary btn-lg" type="submit">
                                    <i class="bi bi-scissors"></i> Acortar
                                </button>
                            </div>
                        </form>

                        <?php if ($message): ?>
                            <div class="alert alert-<?php echo $messageType; ?> alert-dismissible fade show" role="alert">
                                <?php echo $message; ?>
                                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                            </div>
                        <?php endif; ?>

                        <?php if ($shortUrl): ?>
                            <div class="url-result">
                                <h5>Tu URL acortada:</h5>
                                <div class="input-group">
                                    <input type="text" class="form-control" value="<?php echo $shortUrl; ?>" 
                                           id="shortUrlInput" readonly>
                                    <button class="btn btn-success" onclick="copyToClipboard()">
                                        <i class="bi bi-clipboard"></i> Copiar
                                    </button>
                                    <a href="<?php echo $shortUrl; ?>" target="_blank" class="btn btn-info">
                                        <i class="bi bi-box-arrow-up-right"></i> Abrir
                                    </a>
                                    <a href="stats.php?code=<?php echo $shortCode; ?>" class="btn btn-warning">
                                        <i class="bi bi-graph-up"></i> Stats
                                    </a>
                                </div>
                            </div>
                        <?php endif; ?>
                    </div>
                </div>

                <!-- Estadísticas -->
                <div class="row mt-5">
                    <div class="col-md-6">
                        <div class="stats-box text-center">
                            <i class="bi bi-link feature-icon"></i>
                            <h3><?php echo number_format($totalUrls); ?></h3>
                            <p>URLs acortadas</p>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="stats-box text-center">
                            <i class="bi bi-cursor-fill feature-icon"></i>
                            <h3><?php echo number_format($totalClicks); ?></h3>
                            <p>Clicks totales</p>
                        </div>
                    </div>
                </div>

                <!-- Características -->
                <div class="row mt-5">
                    <div class="col-md-4 text-center mb-3">
                        <i class="bi bi-lightning-fill feature-icon"></i>
                        <h5>Rápido</h5>
                        <p>Acorta tus URLs en segundos</p>
                    </div>
                    <div class="col-md-4 text-center mb-3">
                        <i class="bi bi-shield-check feature-icon"></i>
                        <h5>Seguro</h5>
                        <p>Enlaces seguros y confiables</p>
                    </div>
                    <div class="col-md-4 text-center mb-3">
                        <i class="bi bi-graph-up-arrow feature-icon"></i>
                        <h5>Estadísticas</h5>
                        <p>Rastrea clicks y ubicaciones</p>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <footer class="mt-5 py-3 bg-light">
        <div class="container text-center">
            <p class="text-muted mb-0">
                URL Shortener © <?php echo date('Y'); ?>
                <!-- AÑADIDO: Mostrar si está logueado -->
                <?php if (isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in']): ?>
                    | <a href="admin/panel_simple.php">Panel Admin</a>
                <?php else: ?>
                    | <a href="admin/login.php">Admin</a>
                <?php endif; ?>
            </p>
        </div>
    </footer>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        function copyToClipboard() {
            const input = document.getElementById('shortUrlInput');
            input.select();
            document.execCommand('copy');
            
            // Cambiar el texto del botón temporalmente
            const btn = event.target.closest('button');
            const originalHtml = btn.innerHTML;
            btn.innerHTML = '<i class="bi bi-check"></i> Copiado!';
            btn.classList.remove('btn-success');
            btn.classList.add('btn-secondary');
            
            setTimeout(() => {
                btn.innerHTML = originalHtml;
                btn.classList.remove('btn-secondary');
                btn.classList.add('btn-success');
            }, 2000);
        }
    </script>
</body>
</html>

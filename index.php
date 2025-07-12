<?php
session_start();
require_once 'conf.php';
// MANEJAR REDIRECCIONES DE URLs CORTAS
if (isset($_GET['c']) && !empty($_GET['c'])) {
    $shortCode = $_GET['c'];
    
    try {
        // Conexión simple a BD
        $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
        
        // Buscar URL
        $stmt = $pdo->prepare("SELECT id, original_url FROM urls WHERE short_code = ? AND active = 1");
        $stmt->execute([$shortCode]);
        $result = $stmt->fetch();
        
        if ($result && !empty($result['original_url'])) {
            // Actualizar clicks
            $updateStmt = $pdo->prepare("UPDATE urls SET clicks = clicks + 1 WHERE id = ?");
            $updateStmt->execute([$result['id']]);
            
            // Registrar estadísticas básicas
            try {
                $ip = $_SERVER['REMOTE_ADDR'] ?? '';
                $userAgent = $_SERVER['HTTP_USER_AGENT'] ?? '';
                
                $statsStmt = $pdo->prepare("INSERT INTO click_stats (url_id, ip_address, user_agent, clicked_at) VALUES (?, ?, ?, NOW())");
                $statsStmt->execute([$result['id'], $ip, $userAgent]);
            } catch (Exception $e) {
                // Ignorar errores de estadísticas
            }
            
            // Redirigir
            header("Location: " . $result['original_url']);
            exit();
        }
    } catch (Exception $e) {
        // Si falla, continuar con la página normal
        error_log("Error en redirección: " . $e->getMessage());
    }
}
// FIN DE MANEJO DE REDIRECCIONES
// Verificar si el usuario está logueado
$user_logged_in = isset($_SESSION['admin_logged_in']) && $_SESSION['admin_logged_in'] === true;
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
$shortCode = '';
$showLoginModal = false;
// Procesar el formulario de acortamiento
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['url'])) {
    // Verificar si está logueado
    if (!$user_logged_in) {
        $showLoginModal = true;
        $_SESSION['pending_url'] = $_POST['url']; // Guardar la URL para después del login
    } else {
        $url = trim($_POST['url']);
        
        // Validar URL
        if (empty($url)) {
            $message = 'Por favor, introduce una URL';
            $messageType = 'danger';
        } elseif (!filter_var($url, FILTER_VALIDATE_URL)) {
            $message = 'Por favor, introduce una URL válida';
            $messageType = 'danger';
        } else {
            // NUEVO: Verificar que la URL existe
            $headers = @get_headers($url);
            
            if (!$headers || (strpos($headers[0], '200') === false && 
                             strpos($headers[0], '301') === false && 
                             strpos($headers[0], '302') === false)) {
                $message = '❌ La URL no existe o no es accesible. Por favor, verifica que sea correcta.';
                $messageType = 'danger';
            } else {
                // URL válida, continuar con el proceso normal
                try {
                    // Verificar si la URL ya existe para este usuario
                    $stmt = $pdo->prepare("SELECT short_code FROM urls WHERE original_url = ? AND user_id = ?");
                    $stmt->execute([$url, $_SESSION['user_id']]);
                    $existing = $stmt->fetch();
                    
                    if ($existing) {
                        // URL ya existe, devolver el código existente
                        $shortCode = $existing['short_code'];
                        $message = 'Esta URL ya fue acortada anteriormente';
                        $messageType = 'info';
                    } else {
                        // Generar nuevo código único
                        do {
                            $characters = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
                            $shortCode = '';
                            for ($i = 0; $i < 6; $i++) {
                                $shortCode .= $characters[rand(0, strlen($characters) - 1)];
                            }
                            $stmt = $pdo->prepare("SELECT COUNT(*) FROM urls WHERE short_code = ?");
                            $stmt->execute([$shortCode]);
                            $exists = $stmt->fetchColumn();
                        } while ($exists > 0);
                        
                        // Obtener el ID del usuario
                        $user_id = $_SESSION['user_id'];
                        
                        // Insertar nueva URL con user_id
                        $stmt = $pdo->prepare("INSERT INTO urls (short_code, original_url, user_id, created_at) VALUES (?, ?, ?, NOW())");
                        $stmt->execute([$shortCode, $url, $user_id]);
                        
                        $message = '✅ ¡URL acortada con éxito!';
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
    }
}
// Procesar login desde el modal
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['login_submit'])) {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    try {
        // Buscar usuario en la tabla users
        $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ? AND status = 'active'");
        $stmt->execute([$username]);
        $user = $stmt->fetch();
        
        // Verificación especial para admin usando conf.php
        if ($username === ADMIN_USERNAME && $password === ADMIN_PASSWORD) {
            // Login con credenciales de conf.php
            $_SESSION['admin_logged_in'] = true;
            $_SESSION['user_id'] = $user ? $user['id'] : 1;
            $_SESSION['username'] = ADMIN_USERNAME;
            $_SESSION['role'] = 'admin';
            
            if ($user) {
                $pdo->exec("UPDATE users SET last_login = NOW() WHERE id = " . $user['id']);
            }
            
            // Si hay URL pendiente, procesarla
            if (isset($_SESSION['pending_url'])) {
                $_POST['url'] = $_SESSION['pending_url'];
                unset($_SESSION['pending_url']);
            }
            
            // Recargar la página
            header('Location: ' . $_SERVER['PHP_SELF']);
            exit();
        } 
        // Para otros usuarios, usar la verificación normal
        elseif ($user && $user['username'] !== ADMIN_USERNAME && password_verify($password, $user['password'])) {
            // Login normal para otros usuarios
            $_SESSION['admin_logged_in'] = true;
            $_SESSION['user_id'] = $user['id'];
            $_SESSION['username'] = $user['username'];
            $_SESSION['role'] = $user['role'];
            
            $pdo->exec("UPDATE users SET last_login = NOW() WHERE id = " . $user['id']);
            
            // Si hay URL pendiente, procesarla
            if (isset($_SESSION['pending_url'])) {
                $_POST['url'] = $_SESSION['pending_url'];
                unset($_SESSION['pending_url']);
            }
            
            // Recargar la página
            header('Location: ' . $_SERVER['PHP_SELF']);
            exit();
        } else {
            $message = 'Usuario o contraseña incorrectos';
            $messageType = 'danger';
            $showLoginModal = true;
        }
    } catch (Exception $e) {
        $message = 'Error del sistema';
        $messageType = 'danger';
        $showLoginModal = true;
    }
}
// Obtener estadísticas generales
$totalUrls = $pdo->query("SELECT COUNT(*) FROM urls")->fetchColumn();
$totalClicks = $pdo->query("SELECT SUM(clicks) FROM urls")->fetchColumn() ?: 0;
// Si el usuario está logueado, obtener sus estadísticas
$userUrls = 0;
$userClicks = 0;
if ($user_logged_in) {
    $stmt = $pdo->prepare("SELECT COUNT(*) FROM urls WHERE user_id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    $userUrls = $stmt->fetchColumn();
    
    $stmt = $pdo->prepare("SELECT SUM(clicks) FROM urls WHERE user_id = ?");
    $stmt->execute([$_SESSION['user_id']]);
    $userClicks = $stmt->fetchColumn() ?: 0;
}
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
        .user-info-banner {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        /* Estilos para el modal de login */
        .modal-header-gradient {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            border-radius: 0.5rem 0.5rem 0 0;
        }
        .login-icon {
            font-size: 4rem;
            color: #667eea;
            margin-bottom: 20px;
        }
        .modal-body-login {
            padding: 40px;
        }
        .form-control-login {
            padding: 12px;
            border-radius: 10px;
            border: 2px solid #e9ecef;
        }
        .form-control-login:focus {
            border-color: #667eea;
            box-shadow: 0 0 0 0.2rem rgba(102, 126, 234, 0.25);
        }
        .btn-login-modal {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            border: none;
            padding: 12px;
            font-weight: 600;
            border-radius: 10px;
            transition: all 0.3s;
        }
        .btn-login-modal:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.4);
        }
        .divider-text {
            position: relative;
            text-align: center;
            margin: 20px 0;
        }
        .divider-text:before {
            content: '';
            position: absolute;
            top: 50%;
            left: 0;
            right: 0;
            height: 1px;
            background: #e9ecef;
        }
        .divider-text span {
            background: white;
            padding: 0 15px;
            position: relative;
            color: #6c757d;
        }
        /* Estilos para el contenedor QR */
        #qr-container {
            display: none;
            text-align: center;
            margin-top: 20px;
            padding: 20px;
            background: #f8f9fa;
            border-radius: 10px;
            border: 2px dashed #dee2e6;
        }
        #qr-container h6 {
            color: #495057;
            margin-bottom: 15px;
        }
        #qr-image {
            margin: 10px 0;
            padding: 10px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .qr-options {
            display: flex;
            justify-content: center;
            gap: 10px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
    </style>
</head>
<body>
    <?php if (file_exists('menu.php')) include 'menu.php'; ?>
    
    <div class="container main-container">
        <div class="row">
            <div class="col-md-8 mx-auto">
                <!-- Banner de usuario si está logueado -->
                <?php if ($user_logged_in): ?>
                <div class="user-info-banner">
                    <div class="row align-items-center">
                        <div class="col-8">
                            <h5 class="mb-0">
                                <i class="bi bi-person-circle"></i> 
                                ¡Hola <?php echo htmlspecialchars($_SESSION['username']); ?>!
                            </h5>
                            <small>Has creado <?php echo $userUrls; ?> URLs con <?php echo number_format($userClicks); ?> clicks</small>
                        </div>
                        <div class="col-4 text-end">
                            <a href="<?php echo BASE_URL; ?>admin/panel_simple.php" class="btn btn-light btn-sm">
                                <i class="bi bi-speedometer2"></i> Mi Panel
                            </a>
                        </div>
                    </div>
                </div>
                <?php endif; ?>
                
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
                        
                        <?php if ($message && !$showLoginModal): ?>
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
                                    <a href="<?php echo BASE_URL; ?>stats.php?code=<?php echo $shortCode; ?>" class="btn btn-warning">
                                        <i class="bi bi-graph-up"></i> Stats
                                    </a>
                                    <button class="btn btn-secondary" onclick="toggleQR()">
                                        <i class="bi bi-qr-code"></i> QR
                                    </button>
                                </div>
                                
                                <!-- Contenedor del QR -->
                                <div id="qr-container">
                                    <h6>📱 Código QR para tu URL</h6>
                                    <img id="qr-image" src="" alt="Código QR">
                                    <div class="qr-options">
                                        <select id="qr-size" class="form-select form-select-sm" style="width: auto;" onchange="updateQR()">
                                            <option value="150x150">Pequeño</option>
                                            <option value="200x200" selected>Mediano</option>
                                            <option value="300x300">Grande</option>
                                            <option value="500x500">Muy Grande</option>
                                        </select>
                                        <a id="qr-download" href="" download="qr-code.png" class="btn btn-sm btn-primary">
                                            <i class="bi bi-download"></i> Descargar
                                        </a>
                                    </div>
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
                
                <!-- URLs recientes del usuario (si está logueado) -->
                <?php if ($user_logged_in): ?>
                <div class="card mt-5">
                    <div class="card-header">
                        <h5 class="mb-0">
                            <i class="bi bi-clock-history"></i> Tus URLs recientes
                        </h5>
                    </div>
                    <div class="card-body">
                        <?php
                        $stmt = $pdo->prepare("SELECT * FROM urls WHERE user_id = ? ORDER BY created_at DESC LIMIT 5");
                        $stmt->execute([$_SESSION['user_id']]);
                        $recentUrls = $stmt->fetchAll();
                        
                        if ($recentUrls):
                        ?>
                        <div class="table-responsive">
                            <table class="table table-sm">
                                <thead>
                                    <tr>
                                        <th>URL Corta</th>
                                        <th>Clicks</th>
                                        <th>Fecha</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <?php foreach ($recentUrls as $recent): ?>
                                    <tr>
                                        <td>
                                            <a href="<?php echo BASE_URL . $recent['short_code']; ?>" target="_blank">
                                                <?php echo BASE_URL . $recent['short_code']; ?>
                                            </a>
                                        </td>
                                        <td><?php echo $recent['clicks']; ?></td>
                                        <td><?php echo date('d/m/Y', strtotime($recent['created_at'])); ?></td>
                                    </tr>
                                    <?php endforeach; ?>
                                </tbody>
                            </table>
                        </div>
                        <div class="text-center mt-3">
                            <a href="<?php echo BASE_URL; ?>admin/panel_simple.php" class="btn btn-primary btn-sm">
                                Ver todas tus URLs
                            </a>
                        </div>
                        <?php else: ?>
                        <p class="text-muted text-center mb-0">Aún no has acortado ninguna URL</p>
                        <?php endif; ?>
                    </div>
                </div>
                <?php endif; ?>
                
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
    
    <!-- Modal de Login -->
    <div class="modal fade" id="loginModal" tabindex="-1" data-bs-backdrop="static" data-bs-keyboard="false">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header modal-header-gradient border-0">
                    <h5 class="modal-title">
                        <i class="bi bi-person-lock"></i> Iniciar Sesión
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body modal-body-login">
                    <div class="text-center">
                        <i class="bi bi-shield-lock login-icon"></i>
                        <h4 class="mb-4">¡Necesitas una cuenta!</h4>
                        <p class="text-muted mb-4">
                            Para crear URLs cortas y acceder a estadísticas detalladas, 
                            por favor inicia sesión con tu cuenta.
                        </p>
                    </div>
                    
                    <?php if ($message && $showLoginModal): ?>
                        <div class="alert alert-danger">
                            <?php echo $message; ?>
                        </div>
                    <?php endif; ?>
                    
                    <form method="POST" action="">
                        <input type="hidden" name="login_submit" value="1">
                        <?php if (isset($_SESSION['pending_url'])): ?>
                            <input type="hidden" name="url" value="<?php echo htmlspecialchars($_SESSION['pending_url']); ?>">
                        <?php endif; ?>
                        
                        <div class="mb-3">
                            <label class="form-label">
                                <i class="bi bi-person-circle"></i> Usuario
                            </label>
                            <input type="text" class="form-control form-control-login" 
                                   name="username" required autofocus 
                                   placeholder="Ingresa tu usuario">
                        </div>
                        
                        <div class="mb-4">
                            <label class="form-label">
                                <i class="bi bi-key-fill"></i> Contraseña
                            </label>
                            <input type="password" class="form-control form-control-login" 
                                   name="password" required 
                                   placeholder="Ingresa tu contraseña">
                        </div>
                        
                        <div class="d-grid gap-2">
                            <button type="submit" class="btn btn-primary btn-lg btn-login-modal">
                                <i class="bi bi-box-arrow-in-right"></i> Iniciar Sesión
                            </button>
                        </div>
                        
                        <div class="divider-text">
                            <span>o</span>
                        </div>
                        
                        <div class="d-grid gap-2">
                            <a href="<?php echo BASE_URL; ?>admin/login.php" class="btn btn-outline-primary">
                                <i class="bi bi-person-plus"></i> Ir a la página de login
                            </a>
                        </div>
                    </form>
                    
                    <div class="text-center mt-4">
                        <small class="text-muted">
                            ¿No tienes cuenta? Contacta al administrador
                        </small>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <footer class="mt-5 py-3 bg-light">
        <div class="container text-center">
            <p class="text-muted mb-0">
                URL Shortener © <?php echo date('Y'); ?>
                <?php if ($user_logged_in): ?>
                    | <a href="<?php echo BASE_URL; ?>admin/panel_simple.php">Panel Admin</a>
                    | <a href="<?php echo BASE_URL; ?>admin/logout.php">Cerrar sesión</a>
                <?php else: ?>
                    | <a href="<?php echo BASE_URL; ?>admin/login.php">Iniciar sesión</a>
                <?php endif; ?>
            </p>
        </div>
    </footer>
    
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
        // Mostrar modal si es necesario
        <?php if ($showLoginModal): ?>
        document.addEventListener('DOMContentLoaded', function() {
            var loginModal = new bootstrap.Modal(document.getElementById('loginModal'));
            loginModal.show();
        });
        <?php endif; ?>
        
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
        
        // Funciones para QR
        function toggleQR() {
            const qrContainer = document.getElementById('qr-container');
            if (qrContainer.style.display === 'none' || qrContainer.style.display === '') {
                showQR();
            } else {
                qrContainer.style.display = 'none';
            }
        }
        
        function showQR() {
            const qrContainer = document.getElementById('qr-container');
            const shortUrl = '<?php echo $shortUrl ?? ''; ?>';
            
            if (shortUrl) {
                updateQR();
                qrContainer.style.display = 'block';
            }
        }
        
        function updateQR() {
            const qrImage = document.getElementById('qr-image');
            const qrDownload = document.getElementById('qr-download');
            const qrSize = document.getElementById('qr-size').value;
            const shortUrl = '<?php echo $shortUrl ?? ''; ?>';
            
            // Generar QR usando API de qr-server.com (gratis)
            const qrUrl = 'https://api.qrserver.com/v1/create-qr-code/?size=' + qrSize + 
                          '&data=' + encodeURIComponent(shortUrl) + 
                          '&margin=10';
            
            qrImage.src = qrUrl;
            qrDownload.href = qrUrl;
            qrDownload.download = 'qr-<?php echo $shortCode ?? 'code'; ?>.png';
        }
    </script>
</body>
</html>

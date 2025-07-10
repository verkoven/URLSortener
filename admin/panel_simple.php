<?php
session_start();
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] != 1) {
    header('Location: login.php');
    exit;
}
require_once '../conf.php';
$db = Database::getInstance()->getConnection();
$message = '';
$section = $_GET['section'] ?? 'dashboard';
// Procesar eliminación
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['delete_url_id'])) {
    $id = (int)$_POST['delete_url_id'];
    try {
        // Eliminar estadísticas relacionadas
        $stmt = $db->prepare("DELETE FROM click_stats WHERE url_id = ?");
        $stmt->execute([$id]);
        
        // Eliminar URL
        $stmt = $db->prepare("DELETE FROM urls WHERE id = ?");
        $stmt->execute([$id]);
        
        $message = "URL eliminada correctamente";
    } catch (PDOException $e) {
        $message = "Error: " . $e->getMessage();
    }
}
// Obtener estadísticas básicas
try {
    $stmt = $db->query("SELECT COUNT(*) as total_urls FROM urls");
    $total_urls = $stmt->fetch()['total_urls'];
    
    $stmt = $db->query("SELECT SUM(clicks) as total_clicks FROM urls");
    $total_clicks = $stmt->fetch()['total_clicks'] ?? 0;
    
    $avg_clicks = $total_urls > 0 ? round($total_clicks / $total_urls, 1) : 0;
} catch (PDOException $e) {
    $total_urls = 0;
    $total_clicks = 0;
    $avg_clicks = 0;
}
// Obtener URLs si estamos en esa sección
$urls = [];
if ($section === 'urls') {
    try {
        $stmt = $db->query("SELECT * FROM urls ORDER BY created_at DESC LIMIT 100");
        $urls = $stmt->fetchAll();
    } catch (PDOException $e) {
        $message = "Error obteniendo URLs: " . $e->getMessage();
    }
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Panel Admin - Acortador URL</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
            color: #333;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
        }
        .nav {
            background: white;
            border-radius: 8px;
            margin-bottom: 20px;
            padding: 0;
            overflow: hidden;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .nav a {
            display: inline-block;
            padding: 15px 20px;
            text-decoration: none;
            color: #333;
            border-bottom: 3px solid transparent;
            transition: all 0.3s;
        }
        .nav a:hover {
            background: #f8f9fa;
        }
        .nav a.active {
            color: #007bff;
            border-bottom-color: #007bff;
            background: #f8f9fa;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 8px;
            text-align: center;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            transition: transform 0.3s;
        }
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        .stat-number {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            color: #666;
            margin-top: 5px;
        }
        .card {
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        .card-header {
            background: #f8f9fa;
            padding: 20px;
            border-bottom: 1px solid #dee2e6;
            font-weight: bold;
        }
        .card-body {
            padding: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background: #f8f9fa;
            font-weight: bold;
        }
        tbody tr:hover {
            background: #f8f9fa;
        }
        .btn {
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            text-decoration: none;
            display: inline-block;
        }
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        .btn-danger:hover {
            background: #c82333;
        }
        .btn-primary {
            background: #007bff;
            color: white;
            padding: 12px 24px;
            margin: 5px;
            transition: all 0.3s;
        }
        .btn-primary:hover {
            background: #0056b3;
            transform: translateY(-2px);
            box-shadow: 0 5px 10px rgba(0,0,0,0.2);
        }
        .btn-success {
            background: #28a745;
            color: white;
            padding: 12px 24px;
            margin: 5px;
            transition: all 0.3s;
        }
        .btn-success:hover {
            background: #218838;
            transform: translateY(-2px);
            box-shadow: 0 5px 10px rgba(0,0,0,0.2);
        }
        .btn-info {
            background: #17a2b8;
            color: white;
            padding: 12px 24px;
            margin: 5px;
            transition: all 0.3s;
        }
        .btn-info:hover {
            background: #138496;
            transform: translateY(-2px);
            box-shadow: 0 5px 10px rgba(0,0,0,0.2);
        }
        .message {
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .url-code {
            font-family: monospace;
            background: #e9ecef;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 13px;
        }
        .url-original {
            max-width: 400px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            display: block;
            color: #333;
            text-decoration: none;
        }
        .url-original:hover {
            text-decoration: underline;
        }
        .back-links {
            margin-bottom: 20px;
        }
        .back-links a {
            color: #007bff;
            text-decoration: none;
            margin-right: 20px;
        }
        .back-links a:hover {
            text-decoration: underline;
        }
        .overflow-x {
            overflow-x: auto;
        }
        .quick-actions {
            background: white;
            padding: 30px;
            border-radius: 10px;
            text-align: center;
            margin: 30px 0;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .quick-actions h3 {
            margin-bottom: 25px;
            color: #333;
        }
        .action-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            max-width: 800px;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    <!-- Menú simple sin botones no deseados -->
<style>
    .simple-menu {
        background-color: #3a4149;
        padding: 15px 0;
        color: white;
    }
    .simple-menu-container {
        max-width: 1200px;
        margin: 0 auto;
        padding: 0 20px;
        display: flex;
        justify-content: space-between;
        align-items: center;
    }
    .menu-title {
        font-size: 1.5em;
        font-weight: bold;
        display: flex;
        align-items: center;
        gap: 10px;
    }
    .menu-links {
        display: flex;
        gap: 20px;
    }
    .menu-links a {
        color: white;
        text-decoration: none;
        padding: 8px 16px;
        border-radius: 5px;
        transition: background 0.3s;
    }
    .menu-links a:hover {
        background: rgba(255,255,255,0.1);
    }
    .menu-links .btn-acortador {
        background: #28a745;
    }
    .menu-links .btn-salir {
        background: #dc3545;
    }
</style>

<div class="simple-menu">
    <div class="simple-menu-container">
        <div class="menu-title">
            🌐 Acortador URL
        </div>
        <div class="menu-links">
            <a href="../" class="btn-acortador">🔗 Acortador</a>
            <a href="logout.php" class="btn-salir">🚪 Salir</a>
        </div>
    </div>
</div>
    
    <div class="header">
        <h1>🔗 Panel de Administración</h1>
        <p>Usuario: <?php echo htmlspecialchars($_SESSION['admin_user'] ?? 'Admin'); ?></p>
    </div>
    <div class="container">
        <div class="back-links">
            <a href="../">🏠 Ir al Acortador</a>
            <a href="logout.php">🚪 Cerrar Sesión</a>
        </div>
        <!-- Navegación con pestañas -->
        <div class="nav">
            <a href="?section=dashboard" class="<?php echo $section === 'dashboard' ? 'active' : ''; ?>">
                📊 Dashboard
            </a>
            <a href="?section=urls" class="<?php echo $section === 'urls' ? 'active' : ''; ?>">
                🔗 Gestión URLs
            </a>
            <a href="mapa_simple.php">
                🗺️ Mapa Global
            </a>
            <a href="generar_geo.php">
                🌍 Generar Geo
            </a>
            <a href="ver_coordenadas.php">
                📍 Ver Coordenadas
            </a>
        </div>
        <?php if ($message): ?>
            <div class="message"><?php echo htmlspecialchars($message); ?></div>
        <?php endif; ?>
        <?php if ($section === 'dashboard'): ?>
            <!-- Dashboard principal -->
            <div class="stats-grid">
                <div class="stat-card">
                    <div class="stat-number"><?php echo number_format($total_urls); ?></div>
                    <div class="stat-label">Total URLs</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number"><?php echo number_format($total_clicks); ?></div>
                    <div class="stat-label">Total Clicks</div>
                </div>
                <div class="stat-card">
                    <div class="stat-number"><?php echo $avg_clicks; ?></div>
                    <div class="stat-label">Promedio Clicks/URL</div>
                </div>
            </div>
            <!-- Botones de acceso rápido - SIN GEOLOCALIZACIÓN -->
            <div class="quick-actions">
                <h3>🚀 Acciones Rápidas</h3>
                <div class="action-grid">
                    <a href="?section=urls" class="btn btn-primary">
                        🔗 Gestionar URLs
                    </a>
                    <a href="../" class="btn btn-success">
                        ➕ Crear Nueva URL
                    </a>
                    <a href="stats.php" class="btn btn-info">
                        📈 Estadísticas Detalladas
                    </a>
                </div>
            </div>
        <?php elseif ($section === 'urls'): ?>
            <!-- Gestión de URLs -->
            <div class="card">
                <div class="card-header">
                    🔗 URLs Acortadas (<?php echo count($urls); ?> registradas)
                </div>
                <div class="card-body">
                    <div class="overflow-x">
                        <table>
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Código</th>
                                    <th>URL Original</th>
                                    <th>Clicks</th>
                                    <th>Creada</th>
                                    <th>Acciones</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php if (!empty($urls)): ?>
                                    <?php foreach ($urls as $url): ?>
                                    <tr>
                                        <td><?php echo $url['id']; ?></td>
                                        <td>
                                            <span class="url-code"><?php echo htmlspecialchars($url['short_code']); ?></span>
                                            <br>
                                            <a href="<?php echo BASE_URL . $url['short_code']; ?>" 
                                               target="_blank" 
                                               style="font-size: 12px; color: #007bff;">
                                                Ver →
                                            </a>
                                        </td>
                                        <td>
                                            <a href="<?php echo htmlspecialchars($url['original_url']); ?>" 
                                               target="_blank" 
                                               class="url-original"
                                               title="<?php echo htmlspecialchars($url['original_url']); ?>">
                                                <?php echo htmlspecialchars($url['original_url']); ?>
                                            </a>
                                        </td>
                                        <td><?php echo number_format($url['clicks'] ?? 0); ?></td>
                                        <td><?php echo date('d/m/Y H:i', strtotime($url['created_at'])); ?></td>
                                        <td>
                                            <form method="POST" onsubmit="return confirm('¿Eliminar esta URL?');" style="display: inline;">
                                                <input type="hidden" name="delete_url_id" value="<?php echo $url['id']; ?>">
                                                <button type="submit" class="btn btn-danger">Eliminar</button>
                                            </form>
                                        </td>
                                    </tr>
                                    <?php endforeach; ?>
                                <?php else: ?>
                                    <tr>
                                        <td colspan="6" style="text-align: center; padding: 40px; color: #666;">
                                            No hay URLs registradas
                                        </td>
                                    </tr>
                                <?php endif; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        <?php endif; ?>
    </div>
</body>
</html>

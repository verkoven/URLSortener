<?php
session_start();

if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] != 1) {
    header('Location: login.php');
    exit;
}

require_once '../conf.php';
$db = Database::getInstance()->getConnection();

// Período de tiempo (últimos 30 días por defecto)
$days = isset($_GET['days']) ? (int)$_GET['days'] : 30;

// Estadísticas generales
try {
    // Total URLs
    $stmt = $db->query("SELECT COUNT(*) as total FROM urls");
    $total_urls = $stmt->fetch()['total'];
    
    // Total clicks
    $stmt = $db->query("SELECT SUM(clicks) as total FROM urls");
    $total_clicks = $stmt->fetch()['total'] ?? 0;
    
    // URLs creadas en el período
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM urls WHERE created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)");
    $stmt->execute([$days]);
    $new_urls = $stmt->fetch()['total'];
    
    // Clicks en el período
    $stmt = $db->prepare("SELECT COUNT(*) as total FROM click_stats WHERE clicked_at >= DATE_SUB(NOW(), INTERVAL ? DAY)");
    $stmt->execute([$days]);
    $recent_clicks = $stmt->fetch()['total'];
    
    // Top 10 URLs más clickeadas
    $stmt = $db->query("
        SELECT u.*, COUNT(cs.id) as total_clicks
        FROM urls u
        LEFT JOIN click_stats cs ON u.id = cs.url_id
        GROUP BY u.id
        ORDER BY total_clicks DESC
        LIMIT 10
    ");
    $top_urls = $stmt->fetchAll();
    
    // Clicks por día (últimos 30 días)
    $stmt = $db->prepare("
        SELECT DATE(clicked_at) as fecha, COUNT(*) as clicks
        FROM click_stats
        WHERE clicked_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
        GROUP BY DATE(clicked_at)
        ORDER BY fecha ASC
    ");
    $stmt->execute([$days]);
    $clicks_por_dia = $stmt->fetchAll();
    
    // Top países
    $stmt = $db->query("
        SELECT country, COUNT(*) as total
        FROM click_stats
        WHERE country IS NOT NULL AND country != ''
        GROUP BY country
        ORDER BY total DESC
        LIMIT 10
    ");
    $top_countries = $stmt->fetchAll();
    
    // Top ciudades
    $stmt = $db->query("
        SELECT city, country, COUNT(*) as total
        FROM click_stats
        WHERE city IS NOT NULL AND city != ''
        GROUP BY city, country
        ORDER BY total DESC
        LIMIT 10
    ");
    $top_cities = $stmt->fetchAll();
    
    // Navegadores más usados
    $stmt = $db->query("
        SELECT 
            CASE 
                WHEN user_agent LIKE '%Chrome%' THEN 'Chrome'
                WHEN user_agent LIKE '%Firefox%' THEN 'Firefox'
                WHEN user_agent LIKE '%Safari%' AND user_agent NOT LIKE '%Chrome%' THEN 'Safari'
                WHEN user_agent LIKE '%Edge%' THEN 'Edge'
                WHEN user_agent LIKE '%Opera%' THEN 'Opera'
                ELSE 'Otros'
            END as browser,
            COUNT(*) as total
        FROM click_stats
        GROUP BY browser
        ORDER BY total DESC
    ");
    $browsers = $stmt->fetchAll();
    
} catch (PDOException $e) {
    die("Error: " . $e->getMessage());
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Estadísticas Detalladas - Panel Admin</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: Arial, sans-serif;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            text-align: center;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
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
        .filters {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .filters a {
            display: inline-block;
            padding: 8px 16px;
            margin: 5px;
            background: #f8f9fa;
            color: #333;
            text-decoration: none;
            border-radius: 5px;
            transition: all 0.3s;
        }
        .filters a.active {
            background: #007bff;
            color: white;
        }
        .filters a:hover {
            background: #007bff;
            color: white;
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
            border-radius: 10px;
            text-align: center;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            color: #666;
            font-size: 0.9em;
            margin-bottom: 10px;
        }
        .stat-number {
            font-size: 2.5em;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            color: #999;
            font-size: 0.8em;
            margin-top: 5px;
        }
        .card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            margin-bottom: 20px;
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
            color: #666;
        }
        tbody tr:hover {
            background: #f8f9fa;
        }
        .chart-container {
            position: relative;
            height: 300px;
            margin: 20px 0;
        }
        .progress-bar {
            background: #e9ecef;
            border-radius: 5px;
            height: 20px;
            margin: 5px 0;
            overflow: hidden;
        }
        .progress-fill {
            background: #667eea;
            height: 100%;
            transition: width 0.5s ease;
        }
        .url-code {
            font-family: monospace;
            background: #e9ecef;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 13px;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            background: #667eea;
            color: white;
            border-radius: 4px;
            font-size: 12px;
        }
        .two-column {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
        }
        @media (max-width: 768px) {
            .two-column {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <?php include '../menu.php'; ?>
    
    <div class="header">
        <h1>📈 Estadísticas Detalladas</h1>
        <p>Análisis completo de tu acortador de URLs</p>
    </div>

    <div class="container">
        <div class="back-links">
            <a href="panel_simple.php">← Volver al Panel</a>
            <a href="../">🏠 Ir al Acortador</a>
        </div>

        <!-- Filtros de tiempo -->
        <div class="filters">
            <strong>Período:</strong>
            <a href="?days=7" class="<?php echo $days == 7 ? 'active' : ''; ?>">Última semana</a>
            <a href="?days=30" class="<?php echo $days == 30 ? 'active' : ''; ?>">Último mes</a>
            <a href="?days=90" class="<?php echo $days == 90 ? 'active' : ''; ?>">Últimos 3 meses</a>
            <a href="?days=365" class="<?php echo $days == 365 ? 'active' : ''; ?>">Último año</a>
        </div>

        <!-- Estadísticas generales -->
        <div class="stats-grid">
            <div class="stat-card">
                <h3>TOTAL URLs</h3>
                <div class="stat-number"><?php echo number_format($total_urls); ?></div>
                <div class="stat-label">todas las URLs</div>
            </div>
            <div class="stat-card">
                <h3>TOTAL CLICKS</h3>
                <div class="stat-number"><?php echo number_format($total_clicks); ?></div>
                <div class="stat-label">todos los tiempos</div>
            </div>
            <div class="stat-card">
                <h3>NUEVAS URLs</h3>
                <div class="stat-number"><?php echo number_format($new_urls); ?></div>
                <div class="stat-label">últimos <?php echo $days; ?> días</div>
            </div>
            <div class="stat-card">
                <h3>CLICKS RECIENTES</h3>
                <div class="stat-number"><?php echo number_format($recent_clicks); ?></div>
                <div class="stat-label">últimos <?php echo $days; ?> días</div>
            </div>
        </div>

        <!-- Top URLs -->
        <div class="card">
            <div class="card-header">
                🏆 Top 10 URLs Más Clickeadas
            </div>
            <div class="card-body">
                <table>
                    <thead>
                        <tr>
                            <th>Posición</th>
                            <th>Código</th>
                            <th>URL Original</th>
                            <th>Clicks</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php $pos = 1; foreach($top_urls as $url): ?>
                        <tr>
                            <td><span class="badge">#<?php echo $pos++; ?></span></td>
                            <td>
                                <span class="url-code"><?php echo htmlspecialchars($url['short_code']); ?></span>
                            </td>
                            <td>
                                <a href="<?php echo htmlspecialchars($url['original_url']); ?>" 
                                   target="_blank" 
                                   style="color: #333; text-decoration: none;">
                                    <?php echo substr(htmlspecialchars($url['original_url']), 0, 50) . '...'; ?>
                                </a>
                            </td>
                            <td><strong><?php echo number_format($url['total_clicks']); ?></strong></td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

        <div class="two-column">
            <!-- Top Países -->
            <div class="card">
                <div class="card-header">
                    🌍 Top Países
                </div>
                <div class="card-body">
                    <?php 
                    $max_country = $top_countries[0]['total'] ?? 1;
                    foreach($top_countries as $country): 
                        $percentage = ($country['total'] / $max_country) * 100;
                    ?>
                    <div style="margin-bottom: 15px;">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                            <span><?php echo htmlspecialchars($country['country'] ?: 'Desconocido'); ?></span>
                            <strong><?php echo number_format($country['total']); ?></strong>
                        </div>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: <?php echo $percentage; ?>%"></div>
                        </div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>

            <!-- Top Ciudades -->
            <div class="card">
                <div class="card-header">
                    🏙️ Top Ciudades
                </div>
                <div class="card-body">
                    <?php 
                    $max_city = $top_cities[0]['total'] ?? 1;
                    foreach($top_cities as $city): 
                        $percentage = ($city['total'] / $max_city) * 100;
                    ?>
                    <div style="margin-bottom: 15px;">
                        <div style="display: flex; justify-content: space-between; margin-bottom: 5px;">
                            <span><?php echo htmlspecialchars($city['city'] ?: 'Desconocida'); ?></span>
                            <strong><?php echo number_format($city['total']); ?></strong>
                        </div>
                        <div class="progress-bar">
                            <div class="progress-fill" style="width: <?php echo $percentage; ?>%"></div>
                        </div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>

        <!-- Navegadores -->
        <div class="card">
            <div class="card-header">
                🌐 Navegadores Utilizados
            </div>
            <div class="card-body">
                <div style="display: flex; flex-wrap: wrap; gap: 20px;">
                    <?php foreach($browsers as $browser): ?>
                    <div style="flex: 1; min-width: 150px; text-align: center; padding: 20px; background: #f8f9fa; border-radius: 10px;">
                        <div style="font-size: 2em; color: #667eea; font-weight: bold;">
                            <?php echo number_format($browser['total']); ?>
                        </div>
                        <div style="color: #666; margin-top: 5px;">
                            <?php echo htmlspecialchars($browser['browser']); ?>
                        </div>
                    </div>
                    <?php endforeach; ?>
                </div>
            </div>
        </div>
    </div>
</body>
</html>

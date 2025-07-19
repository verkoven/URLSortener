<?php
// analytics_dashboard.php - DASHBOARD SIN TRACKING AUTOMÁTICO
require_once 'config.php';
require_once 'analytics.php';

$user_id = getCurrentUserId();
if (!$user_id) {
    die('❌ No autenticado - <a href="../admin/login.php">Iniciar sesión</a>');
}

// ⚠️ IMPORTANTE: NO hacer tracking aquí, solo LEER datos
$analytics = new UrlAnalytics($pdo);

// Obtener período de análisis
$days = $_GET['days'] ?? 30;
$days = max(1, min(365, intval($days))); // Entre 1 y 365 días

// Obtener stats del usuario (SOLO LECTURA)
$stats = $analytics->getUserStats($user_id, $days);

if (!$stats) {
    $stats = [
        'general' => ['total_clicks' => 0, 'unique_visitors' => 0, 'urls_clicked' => 0, 'active_days' => 0],
        'top_urls' => [],
        'daily_clicks' => [],
        'top_countries' => [],
        'devices' => [],
        'browsers' => []
    ];
}

$userInfo = getCurrentUserInfo();
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 Analytics Dashboard - <?= htmlspecialchars($userInfo['username']) ?></title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }
        
        .header {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-bottom: 1px solid rgba(255, 255, 255, 0.2);
            padding: 20px 0;
            color: white;
            position: sticky;
            top: 0;
            z-index: 100;
        }
        
        .header-content {
            max-width: 1200px;
            margin: 0 auto;
            padding: 0 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        
        .logo {
            font-size: 1.8em;
            font-weight: bold;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .header-actions {
            display: flex;
            gap: 15px;
        }
        
        .btn-header {
            background: rgba(255, 255, 255, 0.2);
            color: white;
            padding: 10px 20px;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 500;
            transition: all 0.3s;
        }
        
        .btn-header:hover {
            background: rgba(255, 255, 255, 0.3);
            transform: translateY(-1px);
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 30px 20px;
        }
        
        .dashboard-header {
            background: white;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 30px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .dashboard-title {
            font-size: 2.5em;
            color: #2c3e50;
            margin-bottom: 10px;
            display: flex;
            align-items: center;
            gap: 15px;
        }
        
        .period-selector {
            margin-top: 20px;
            display: flex;
            gap: 10px;
            align-items: center;
        }
        
        .period-btn {
            padding: 8px 16px;
            border: 2px solid #667eea;
            background: white;
            color: #667eea;
            text-decoration: none;
            border-radius: 20px;
            font-weight: 500;
            transition: all 0.3s;
        }
        
        .period-btn.active,
        .period-btn:hover {
            background: #667eea;
            color: white;
        }
        
        .stats-overview {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            text-align: center;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            transition: transform 0.3s;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
        }
        
        .stat-icon {
            font-size: 2.5em;
            margin-bottom: 15px;
        }
        
        .stat-number {
            font-size: 2.5em;
            font-weight: 700;
            color: #667eea;
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #6c757d;
            font-weight: 500;
        }
        
        .charts-section {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .chart-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .chart-title {
            font-size: 1.4em;
            color: #2c3e50;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .chart-container {
            position: relative;
            height: 300px;
        }
        
        .data-tables {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .table-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .table-title {
            font-size: 1.3em;
            color: #2c3e50;
            margin-bottom: 20px;
            display: flex;
            align-items: center;
            gap: 10px;
        }
        
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        
        .data-table th,
        .data-table td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #f1f3f5;
        }
        
        .data-table th {
            background: #f8f9fa;
            font-weight: 600;
            color: #495057;
        }
        
        .data-table tr:hover {
            background: #f8f9fa;
        }
        
        .badge {
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 500;
        }
        
        .badge-primary {
            background: #e3f2fd;
            color: #2196f3;
        }
        
        .flag {
            width: 20px;
            height: 15px;
            margin-right: 8px;
            border-radius: 2px;
        }
        
        .no-data {
            text-align: center;
            color: #6c757d;
            font-style: italic;
            padding: 40px;
        }
        
        .actions {
            text-align: center;
            margin-top: 30px;
        }
        
        .btn {
            background: #667eea;
            color: white;
            padding: 12px 25px;
            text-decoration: none;
            border-radius: 8px;
            margin: 0 10px;
            display: inline-block;
            font-weight: 500;
            transition: all 0.3s;
        }
        
        .btn:hover {
            background: #5a67d8;
            transform: translateY(-2px);
        }
        
        .btn-secondary {
            background: #6c757d;
        }
        
        .btn-secondary:hover {
            background: #5a6268;
        }
        
        @media (max-width: 768px) {
            .charts-section {
                grid-template-columns: 1fr;
            }
            
            .data-tables {
                grid-template-columns: 1fr;
            }
            
            .stats-overview {
                grid-template-columns: repeat(2, 1fr);
            }
            
            .period-selector {
                flex-wrap: wrap;
            }
        }
    </style>
</head>
<body>
    <!-- Header -->
    <header class="header">
        <div class="header-content">
            <div class="logo">
                <span>📊</span>
                <span>Analytics Dashboard</span>
            </div>
            <div class="header-actions">
                <a href="index.php" class="btn-header">🔗 Gestor URLs</a>
                <a href="analytics_export.php" class="btn-header">📥 Exportar</a>
                <a href="../admin/panel_simple.php" class="btn-header">⚙️ Admin</a>
            </div>
        </div>
    </header>
    
    <div class="container">
        <!-- Dashboard Header -->
        <div class="dashboard-header">
            <h1 class="dashboard-title">
                <span>👤</span>
                Analytics de <?= htmlspecialchars($userInfo['username']) ?>
            </h1>
            <p style="color: #6c757d; font-size: 1.1em;">
                Análisis detallado de tus URLs en los últimos <?= $days ?> días
            </p>
            
            <div class="period-selector">
                <span style="color: #6c757d; font-weight: 500;">Período:</span>
                <a href="?days=7" class="period-btn <?= $days == 7 ? 'active' : '' ?>">7 días</a>
                <a href="?days=30" class="period-btn <?= $days == 30 ? 'active' : '' ?>">30 días</a>
                <a href="?days=90" class="period-btn <?= $days == 90 ? 'active' : '' ?>">90 días</a>
                <a href="?days=365" class="period-btn <?= $days == 365 ? 'active' : '' ?>">1 año</a>
            </div>
        </div>
        
        <!-- Stats Overview -->
        <div class="stats-overview">
            <div class="stat-card">
                <div class="stat-icon">👆</div>
                <div class="stat-number"><?= number_format($stats['general']['total_clicks']) ?></div>
                <div class="stat-label">Total Clicks</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-number"><?= number_format($stats['general']['unique_visitors']) ?></div>
                <div class="stat-label">Visitantes Únicos</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">🔗</div>
                <div class="stat-number"><?= number_format($stats['general']['urls_clicked']) ?></div>
                <div class="stat-label">URLs Clickeadas</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">📅</div>
                <div class="stat-number"><?= number_format($stats['general']['active_days']) ?></div>
                <div class="stat-label">Días Activos</div>
            </div>
        </div>
        
        <?php if ($stats['general']['total_clicks'] > 0): ?>
        
        <!-- Charts Section -->
        <div class="charts-section">
            <!-- Daily Clicks Chart -->
            <div class="chart-card">
                <h3 class="chart-title">📈 Clicks por Día</h3>
                <div class="chart-container">
                    <canvas id="dailyChart"></canvas>
                </div>
            </div>
            
            <!-- Devices Chart -->
            <div class="chart-card">
                <h3 class="chart-title">📱 Dispositivos</h3>
                <div class="chart-container">
                    <canvas id="devicesChart"></canvas>
                </div>
            </div>
        </div>
        
        <!-- Data Tables -->
        <div class="data-tables">
            <!-- Top URLs -->
            <div class="table-card">
                <h3 class="table-title">🏆 Top URLs</h3>
                <?php if (!empty($stats['top_urls'])): ?>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>URL</th>
                            <th>Clicks</th>
                            <th>Únicos</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach (array_slice($stats['top_urls'], 0, 10) as $url): ?>
                        <tr>
                            <td>
                                <a href="analytics_url.php?url_id=<?= $url['url_id'] ?>" 
                                   style="color: #667eea; text-decoration: none;">
                                    <?= htmlspecialchars($url['short_code']) ?>
                                </a>
                            </td>
                            <td><span class="badge badge-primary"><?= number_format($url['clicks']) ?></span></td>
                            <td><?= number_format($url['unique_visitors']) ?></td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
                <?php else: ?>
                <div class="no-data">No hay datos de URLs</div>
                <?php endif; ?>
            </div>
            
            <!-- Top Countries -->
            <div class="table-card">
                <h3 class="table-title">🌍 Top Países</h3>
                <?php if (!empty($stats['top_countries'])): ?>
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>País</th>
                            <th>Clicks</th>
                            <th>Únicos</th>
                        </tr>
                    </thead>
                    <tbody>
                        <?php foreach (array_slice($stats['top_countries'], 0, 10) as $country): ?>
                        <tr>
                            <td>
                                <img src="https://flagcdn.com/w20/<?= strtolower($country['country_code']) ?>.png" 
                                     class="flag" alt="<?= $country['country_code'] ?>">
                                <?= htmlspecialchars($country['country']) ?>
                            </td>
                            <td><span class="badge badge-primary"><?= number_format($country['clicks']) ?></span></td>
                            <td><?= number_format($country['unique_visitors']) ?></td>
                        </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
                <?php else: ?>
                <div class="no-data">No hay datos de países</div>
                <?php endif; ?>
            </div>
        </div>
        
        <?php else: ?>
        
        <!-- No Data State -->
        <div class="chart-card">
            <div class="no-data">
                <h3>📊 Sin datos todavía</h3>
                <p>Tus URLs aún no han recibido clicks en los últimos <?= $days ?> días.</p>
                <p>¡Comparte tus enlaces para empezar a ver estadísticas!</p>
            </div>
        </div>
        
        <?php endif; ?>
        
        <!-- Actions -->
        <div class="actions">
            <a href="index.php" class="btn btn-secondary">← Volver al Gestor</a>
            <a href="analytics_export.php?format=csv" class="btn">📥 Exportar CSV</a>
            <a href="analytics_export.php?format=json" class="btn">📥 Exportar JSON</a>
        </div>
    </div>
    
    <script>
        // =====================================================
        // CHARTS CONFIGURACIÓN (SIN TRACKING)
        // =====================================================
        
        <?php if ($stats['general']['total_clicks'] > 0): ?>
        
        // Daily clicks chart
        const dailyData = {
            labels: [
                <?php 
                $dailyLabels = [];
                $dailyValues = [];
                $clicksByDate = [];
                
                foreach ($stats['daily_clicks'] as $click) {
                    $clicksByDate[$click['date']] = $click['clicks'];
                }
                
                for ($i = $days - 1; $i >= 0; $i--) {
                    $date = date('Y-m-d', strtotime("-{$i} days"));
                    $label = date('d/m', strtotime($date));
                    $clicks = $clicksByDate[$date] ?? 0;
                    
                    echo "'{$label}'" . ($i > 0 ? ',' : '');
                }
                ?>
            ],
            datasets: [{
                label: 'Clicks',
                data: [
                    <?php
                    for ($i = $days - 1; $i >= 0; $i--) {
                        $date = date('Y-m-d', strtotime("-{$i} days"));
                        $clicks = $clicksByDate[$date] ?? 0;
                        echo $clicks . ($i > 0 ? ',' : '');
                    }
                    ?>
                ],
                borderColor: '#667eea',
                backgroundColor: 'rgba(102, 126, 234, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4
            }]
        };
        
        // Devices chart
        const devicesData = {
            labels: [
                <?php
                if (!empty($stats['devices'])) {
                    foreach ($stats['devices'] as $i => $device) {
                        echo "'" . ucfirst($device['device_type']) . "'" . ($i < count($stats['devices']) - 1 ? ',' : '');
                    }
                } else {
                    echo "'Sin datos'";
                }
                ?>
            ],
            datasets: [{
                data: [
                    <?php
                    if (!empty($stats['devices'])) {
                        foreach ($stats['devices'] as $i => $device) {
                            echo $device['clicks'] . ($i < count($stats['devices']) - 1 ? ',' : '');
                        }
                    } else {
                        echo "0";
                    }
                    ?>
                ],
                backgroundColor: [
                    '#667eea',
                    '#764ba2',
                    '#f093fb',
                    '#f5576c',
                    '#4facfe'
                ]
            }]
        };
        
        // Chart options
        const lineOptions = {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                y: { beginAtZero: true, min: 0 },
                x: { grid: { color: 'rgba(0,0,0,0.1)' } }
            }
        };
        
        const doughnutOptions = {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    position: 'bottom',
                    labels: { padding: 20 }
                }
            }
        };
        
        // Create charts
        const dailyCtx = document.getElementById('dailyChart').getContext('2d');
        new Chart(dailyCtx, {
            type: 'line',
            data: dailyData,
            options: lineOptions
        });
        
        const devicesCtx = document.getElementById('devicesChart').getContext('2d');
        new Chart(devicesCtx, {
            type: 'doughnut',
            data: devicesData,
            options: doughnutOptions
        });
        
        <?php endif; ?>
        
        console.log('✅ Dashboard cargado SIN tracking automático');
        
        // ⚠️ NO hacer fetch automático ni setInterval
        // ⚠️ NO hacer llamadas a APIs de tracking
        // ⚠️ Solo mostrar datos ya existentes
    </script>
</body>
</html>

<?php
// analytics_url.php - GRÁFICOS ARREGLADOS
require_once 'config.php';
require_once 'analytics.php';

$user_id = getCurrentUserId();
if (!$user_id) {
    die('❌ No autenticado - <a href="../admin/login.php">Iniciar sesión</a>');
}

$url_id = $_GET['url_id'] ?? null;
if (!$url_id) {
    die('❌ URL ID requerido');
}

// Obtener stats de la URL
$analytics = new UrlAnalytics($pdo);
$stats = $analytics->getUrlStats($url_id, $user_id, 30);

if (!$stats) {
    die('❌ URL no encontrada o no autorizada');
}

$urlInfo = $stats['url_info'];
$general = $stats['general'];
$dailyClicks = $stats['daily_clicks'];
$hourlyClicks = $stats['hourly_clicks'];

// Construir URL corta
$domain = $urlInfo['domain'] ?? '0ln.org';
$shortUrl = "https://{$domain}/{$urlInfo['short_code']}";
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>📊 Analytics - <?= htmlspecialchars($urlInfo['short_code']) ?></title>
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
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header-card {
            background: white;
            border-radius: 15px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .url-title {
            font-size: 2em;
            color: #2c3e50;
            margin-bottom: 15px;
            word-break: break-all;
        }
        
        .url-info {
            color: #6c757d;
            line-height: 1.6;
        }
        
        .url-info a {
            color: #667eea;
            text-decoration: none;
        }
        
        .url-info a:hover {
            text-decoration: underline;
        }
        
        .stats-grid {
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
            opacity: 0.8;
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
        
        .charts-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .chart-card {
            background: white;
            border-radius: 15px;
            padding: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            height: 400px;
        }
        
        .chart-title {
            font-size: 1.3em;
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
            .charts-grid {
                grid-template-columns: 1fr;
            }
            
            .stats-grid {
                grid-template-columns: repeat(2, 1fr);
            }
            
            .chart-card {
                height: 350px;
            }
            
            .chart-container {
                height: 250px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header Card -->
        <div class="header-card">
            <h1 class="url-title"><?= htmlspecialchars($urlInfo['title'] ?: $urlInfo['short_code']) ?></h1>
            <div class="url-info">
                <p><strong>🔗 Código:</strong> <?= htmlspecialchars($urlInfo['short_code']) ?></p>
                <p><strong>📅 Creado:</strong> <?= date('d/m/Y H:i', strtotime($urlInfo['created_at'])) ?></p>
                <p><strong>🌐 Dominio:</strong> <?= htmlspecialchars($domain) ?></p>
                <p><strong>📍 URL Corta:</strong> <a href="<?= htmlspecialchars($shortUrl) ?>" target="_blank"><?= htmlspecialchars($shortUrl) ?></a></p>
                <p><strong>🎯 URL Destino:</strong> <a href="<?= htmlspecialchars($urlInfo['original_url']) ?>" target="_blank"><?= htmlspecialchars($urlInfo['original_url']) ?></a></p>
            </div>
        </div>
        
        <!-- Stats Grid -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-icon">👆</div>
                <div class="stat-number"><?= number_format($general['total_clicks'] ?? 0) ?></div>
                <div class="stat-label">Total Clicks</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">👥</div>
                <div class="stat-number"><?= number_format($general['unique_visitors'] ?? 0) ?></div>
                <div class="stat-label">Visitantes Únicos</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">🌐</div>
                <div class="stat-number"><?= number_format($general['unique_ips'] ?? 0) ?></div>
                <div class="stat-label">IPs Únicas</div>
            </div>
            
            <div class="stat-card">
                <div class="stat-icon">📅</div>
                <div class="stat-number"><?= $general['first_click'] ? \ceil((time() - strtotime($general['first_click'])) / 86400) : 0 ?></div>
                <div class="stat-label">Días Activo</div>
            </div>
        </div>
        
        <!-- Charts Grid -->
        <div class="charts-grid">
            <!-- Daily Clicks Chart -->
            <div class="chart-card">
                <h3 class="chart-title">📊 Clicks por Día</h3>
                <div class="chart-container">
                    <canvas id="dailyChart"></canvas>
                </div>
            </div>
            
            <!-- Hourly Clicks Chart -->
            <div class="chart-card">
                <h3 class="chart-title">🕐 Clicks por Hora (últimos 7 días)</h3>
                <div class="chart-container">
                    <canvas id="hourlyChart"></canvas>
                </div>
            </div>
        </div>
        
        <!-- Actions -->
        <div class="actions">
            <a href="index.php" class="btn btn-secondary">← Volver al Gestor</a>
            <a href="analytics_dashboard.php" class="btn">📊 Dashboard Completo</a>
            <a href="analytics_export.php?url_id=<?= $url_id ?>" class="btn">📥 Exportar Datos</a>
        </div>
    </div>
    
    <script>
        // =====================================================
        // CONFIGURACIÓN CHART.JS CORREGIDA
        // =====================================================
        
        // Datos para gráfico diario
        const dailyData = {
            labels: [
                <?php 
                // Generar labels de los últimos 30 días
                for ($i = 29; $i >= 0; $i--) {
                    $date = date('d/m', strtotime("-{$i} days"));
                    echo "'{$date}'" . ($i > 0 ? ',' : '');
                }
                ?>
            ],
            datasets: [{
                label: 'Clicks',
                data: [
                    <?php
                    // Generar datos de clicks por día
                    $clicksByDate = [];
                    foreach ($dailyClicks as $click) {
                        $clicksByDate[$click['date']] = $click['clicks'];
                    }
                    
                    for ($i = 29; $i >= 0; $i--) {
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
        
        // Datos para gráfico por hora
        const hourlyData = {
            labels: [
                <?php
                for ($h = 0; $h <= 23; $h++) {
                    echo "'{$h}:00'" . ($h < 23 ? ',' : '');
                }
                ?>
            ],
            datasets: [{
                label: 'Clicks',
                data: [
                    <?php
                    $clicksByHour = [];
                    foreach ($hourlyClicks as $click) {
                        $clicksByHour[$click['hour']] = $click['clicks'];
                    }
                    
                    for ($h = 0; $h <= 23; $h++) {
                        $clicks = $clicksByHour[$h] ?? 0;
                        echo $clicks . ($h < 23 ? ',' : '');
                    }
                    ?>
                ],
                borderColor: '#764ba2',
                backgroundColor: 'rgba(118, 75, 162, 0.1)',
                borderWidth: 3,
                fill: true,
                tension: 0.4
            }]
        };
        
        // CONFIGURACIÓN CORREGIDA PARA LOS GRÁFICOS
        const chartOptions = {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    display: false
                }
            },
            scales: {
                y: {
                    beginAtZero: true,  // ✅ CLAVE: Empezar desde 0
                    min: 0,             // ✅ CLAVE: Mínimo 0
                    ticks: {
                        stepSize: 1,    // ✅ Incrementos de 1
                        precision: 0    // ✅ Sin decimales
                    },
                    grid: {
                        color: 'rgba(0,0,0,0.1)'
                    }
                },
                x: {
                    grid: {
                        color: 'rgba(0,0,0,0.1)'
                    }
                }
            },
            elements: {
                point: {
                    radius: 4,
                    hoverRadius: 6
                }
            }
        };
        
        // Crear gráficos
        const dailyCtx = document.getElementById('dailyChart').getContext('2d');
        const dailyChart = new Chart(dailyCtx, {
            type: 'line',
            data: dailyData,
            options: chartOptions
        });
        
        const hourlyCtx = document.getElementById('hourlyChart').getContext('2d');
        const hourlyChart = new Chart(hourlyCtx, {
            type: 'line',
            data: hourlyData,
            options: chartOptions
        });
        
        console.log('✅ Gráficos cargados correctamente');
    </script>
</body>
</html>

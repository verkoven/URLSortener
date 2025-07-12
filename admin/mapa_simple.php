<?php
session_start();
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] != 1) {
    header('Location: login.php');
    exit;
}

require_once '../conf.php';

// Conexión a la base de datos
try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die("Error de conexión: " . $e->getMessage());
}

// Obtener ciudad seleccionada si existe
$selected_city = $_GET['city'] ?? '';

if ($selected_city) {
    // Mostrar todas las ubicaciones de una ciudad específica
    $stmt = $db->prepare("
        SELECT 
            latitude,
            longitude,
            city,
            country,
            ip_address,
            COUNT(*) as clicks,
            MAX(clicked_at) as last_click
        FROM click_stats
        WHERE city = ? AND latitude IS NOT NULL AND longitude IS NOT NULL
        GROUP BY latitude, longitude, ip_address
        ORDER BY clicks DESC
    ");
    $stmt->execute([$selected_city]);
    $locations = $stmt->fetchAll();
    
    // Obtener información resumida de la ciudad
    $stmt_summary = $db->prepare("
        SELECT 
            city,
            country,
            COUNT(DISTINCT ip_address) as unique_visitors,
            COUNT(*) as total_clicks,
            MIN(clicked_at) as first_click,
            MAX(clicked_at) as last_click
        FROM click_stats
        WHERE city = ?
        GROUP BY city, country
    ");
    $stmt_summary->execute([$selected_city]);
    $city_summary = $stmt_summary->fetch();
    
} else {
    // Mostrar resumen por ciudades
    $stmt = $db->query("
        SELECT 
            city,
            country,
            COUNT(*) as total_clicks,
            COUNT(DISTINCT ip_address) as unique_visitors,
            COUNT(DISTINCT latitude, longitude) as locations_count,
            MIN(latitude) as min_lat,
            MAX(latitude) as max_lat,
            MIN(longitude) as min_lng,
            MAX(longitude) as max_lng,
            AVG(latitude) as avg_lat,
            AVG(longitude) as avg_lng
        FROM click_stats
        WHERE latitude IS NOT NULL AND longitude IS NOT NULL AND city IS NOT NULL
        GROUP BY city, country
        ORDER BY total_clicks DESC
        LIMIT 100
    ");
    $cities = $stmt->fetchAll();
}

// Obtener estadísticas generales
$stmt_stats = $db->query("
    SELECT 
        COUNT(DISTINCT city) as total_cities,
        COUNT(DISTINCT country) as total_countries,
        COUNT(*) as total_clicks,
        COUNT(DISTINCT ip_address) as total_visitors
    FROM click_stats
    WHERE latitude IS NOT NULL AND longitude IS NOT NULL
");
$general_stats = $stmt_stats->fetch();
?>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Ubicaciones - Vista Simple</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .location-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
        }
        .city-card, .location-card {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            transition: transform 0.3s;
            position: relative;
        }
        .city-card:hover, .location-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        .city-card {
            cursor: pointer;
        }
        .city-card h3, .location-card h3 {
            margin: 0 0 10px 0;
            color: #333;
        }
        .clicks {
            font-size: 2em;
            color: #667eea;
            font-weight: bold;
            margin: 10px 0;
        }
        .map-link, .view-details {
            display: inline-block;
            padding: 8px 16px;
            background: #28a745;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 10px;
            margin-right: 10px;
        }
        .map-link:hover, .view-details:hover {
            background: #218838;
        }
        .view-details {
            background: #007bff;
        }
        .view-details:hover {
            background: #0056b3;
        }
        .back {
            display: inline-block;
            padding: 10px 20px;
            background: #007bff;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .stats {
            background: white;
            padding: 20px;
            border-radius: 10px;
            margin-bottom: 20px;
            text-align: center;
        }
        .stats span {
            display: inline-block;
            margin: 0 20px;
            font-size: 1.2em;
        }
        .stats strong {
            color: #667eea;
        }
        .city-summary {
            background: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .city-summary h2 {
            margin-top: 0;
            color: #333;
        }
        .summary-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        .summary-item {
            text-align: center;
        }
        .summary-item .value {
            font-size: 2em;
            color: #667eea;
            font-weight: bold;
        }
        .summary-item .label {
            color: #666;
            margin-top: 5px;
        }
        .map-all {
            display: inline-block;
            padding: 12px 24px;
            background: #e74c3c;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            margin-top: 20px;
            font-weight: bold;
        }
        .map-all:hover {
            background: #c0392b;
        }
        .badge {
            display: inline-block;
            padding: 4px 8px;
            background: #f0f0f0;
            border-radius: 4px;
            font-size: 0.85em;
            margin-left: 10px;
        }
        .badge-visitors {
            background: #e3f2fd;
            color: #1976d2;
        }
        .badge-locations {
            background: #f3e5f5;
            color: #7b1fa2;
        }
        .filter-info {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            color: #856404;
        }
        .location-detail {
            font-size: 0.9em;
            color: #666;
            margin-top: 10px;
        }
        .ip-address {
            font-family: monospace;
            background: #f5f5f5;
            padding: 2px 5px;
            border-radius: 3px;
        }
    </style>
</head>
<body>
    <?php 
    // Incluir menú si existe
    if (file_exists('../menu.php')) {
        include '../menu.php';
    }
    ?>
    
    <div class="header">
        <h1>📍 Ubicaciones de Clicks</h1>
        <p><?php echo $selected_city ? 'Detalle de ' . htmlspecialchars($selected_city) : 'Vista por ciudades'; ?></p>
    </div>
    
    <div class="container">
        <a href="panel_simple.php" class="back">← Volver al Panel</a>
        <?php if ($selected_city): ?>
            <a href="mapa_simple.php" class="back">← Ver todas las ciudades</a>
        <?php endif; ?>
        
        <div class="stats">
            <span><strong><?php echo $general_stats['total_cities']; ?></strong> Ciudades</span>
            <span><strong><?php echo $general_stats['total_countries']; ?></strong> Países</span>
            <span><strong><?php echo number_format($general_stats['total_clicks']); ?></strong> Clicks totales</span>
            <span><strong><?php echo number_format($general_stats['total_visitors']); ?></strong> Visitantes únicos</span>
        </div>
        
        <?php if ($selected_city): ?>
            <!-- Vista detallada de una ciudad -->
            <?php if ($city_summary): ?>
            <div class="city-summary">
                <h2>📍 <?php echo htmlspecialchars($city_summary['city']); ?>, <?php echo htmlspecialchars($city_summary['country']); ?></h2>
                
                <div class="summary-grid">
                    <div class="summary-item">
                        <div class="value"><?php echo number_format($city_summary['total_clicks']); ?></div>
                        <div class="label">Clicks Totales</div>
                    </div>
                    <div class="summary-item">
                        <div class="value"><?php echo number_format($city_summary['unique_visitors']); ?></div>
                        <div class="label">Visitantes Únicos</div>
                    </div>
                    <div class="summary-item">
                        <div class="value"><?php echo count($locations); ?></div>
                        <div class="label">Ubicaciones Diferentes</div>
                    </div>
                    <div class="summary-item">
                        <div class="value"><?php echo date('d/m/Y', strtotime($city_summary['first_click'])); ?></div>
                        <div class="label">Primera Visita</div>
                    </div>
                </div>
                
                <?php if (count($locations) > 0): ?>
                    <?php
                    // Crear URL para Google Maps con múltiples marcadores
                    $map_url = "https://www.google.com/maps/dir/";
                    foreach ($locations as $loc) {
                        $map_url .= $loc['latitude'] . "," . $loc['longitude'] . "/";
                    }
                    ?>
                    <center>
                        <a href="<?php echo $map_url; ?>" target="_blank" class="map-all">
                            🗺️ Ver todas las ubicaciones en Google Maps
                        </a>
                    </center>
                <?php endif; ?>
            </div>
            <?php endif; ?>
            
            <div class="filter-info">
                <strong>Mostrando todas las ubicaciones de <?php echo htmlspecialchars($selected_city); ?></strong>
            </div>
            
            <div class="location-grid">
                <?php foreach($locations as $loc): ?>
                <div class="location-card">
                    <h3>📍 Ubicación específica</h3>
                    <p><?php echo htmlspecialchars($loc['city']); ?>, <?php echo htmlspecialchars($loc['country']); ?></p>
                    <div class="clicks"><?php echo $loc['clicks']; ?> clicks</div>
                    <div class="location-detail">
                        <p><strong>Coordenadas:</strong> <?php echo round($loc['latitude'], 6) . ', ' . round($loc['longitude'], 6); ?></p>
                        <p><strong>IP:</strong> <span class="ip-address"><?php echo htmlspecialchars($loc['ip_address']); ?></span></p>
                        <p><strong>Último click:</strong> <?php echo date('d/m/Y H:i', strtotime($loc['last_click'])); ?></p>
                    </div>
                    <a href="https://www.google.com/maps?q=<?php echo $loc['latitude'] . ',' . $loc['longitude']; ?>" 
                       target="_blank" 
                       class="map-link">
                        Ver en Google Maps →
                    </a>
                </div>
                <?php endforeach; ?>
            </div>
            
        <?php else: ?>
            <!-- Vista general por ciudades -->
            <div class="location-grid">
                <?php foreach($cities as $city): ?>
                <div class="city-card" onclick="window.location.href='?city=<?php echo urlencode($city['city']); ?>'">
                    <h3><?php echo htmlspecialchars($city['city'] ?: 'Ciudad desconocida'); ?></h3>
                    <p><?php echo htmlspecialchars($city['country'] ?: 'País desconocido'); ?></p>
                    <div class="clicks"><?php echo number_format($city['total_clicks']); ?> clicks</div>
                    
                    <p>
                        <span class="badge badge-visitors">👥 <?php echo $city['unique_visitors']; ?> visitantes</span>
                        <span class="badge badge-locations">📍 <?php echo $city['locations_count']; ?> ubicaciones</span>
                    </p>
                    
                    <a href="?city=<?php echo urlencode($city['city']); ?>" class="view-details">
                        Ver detalles →
                    </a>
                    <a href="https://www.google.com/maps?q=<?php echo $city['avg_lat'] . ',' . $city['avg_lng']; ?>&z=12" 
                       target="_blank" 
                       class="map-link"
                       onclick="event.stopPropagation();">
                        Ver en mapa →
                    </a>
                </div>
                <?php endforeach; ?>
            </div>
        <?php endif; ?>
    </div>
    
    <script>
    // Prevenir que el click en los enlaces active el onclick de la tarjeta
    document.querySelectorAll('.city-card a').forEach(link => {
        link.addEventListener('click', (e) => {
            e.stopPropagation();
        });
    });
    </script>
</body>
</html>

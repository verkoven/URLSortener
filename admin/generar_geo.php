<?php
session_start();

if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] != 1) {
    header('Location: login.php');
    exit;
}

require_once '../conf.php';
$db = Database::getInstance()->getConnection();

$message = '';

// Ciudades españolas con coordenadas reales
$ciudades_espana = [
    ['city' => 'Madrid', 'lat' => 40.4168, 'lon' => -3.7038, 'country' => 'España'],
    ['city' => 'Barcelona', 'lat' => 41.3851, 'lon' => 2.1734, 'country' => 'España'],
    ['city' => 'Valencia', 'lat' => 39.4699, 'lon' => -0.3763, 'country' => 'España'],
    ['city' => 'Sevilla', 'lat' => 37.3891, 'lon' => -5.9845, 'country' => 'España'],
    ['city' => 'Bilbao', 'lat' => 43.2630, 'lon' => -2.9350, 'country' => 'España'],
    ['city' => 'Málaga', 'lat' => 36.7213, 'lon' => -4.4214, 'country' => 'España'],
    ['city' => 'Zaragoza', 'lat' => 41.6488, 'lon' => -0.8891, 'country' => 'España'],
    ['city' => 'Murcia', 'lat' => 37.9922, 'lon' => -1.1307, 'country' => 'España'],
    ['city' => 'Palma', 'lat' => 39.5696, 'lon' => 2.6502, 'country' => 'España'],
    ['city' => 'Las Palmas', 'lat' => 28.1235, 'lon' => -15.4363, 'country' => 'España']
];

// Ciudades internacionales
$ciudades_mundo = [
    ['city' => 'París', 'lat' => 48.8566, 'lon' => 2.3522, 'country' => 'Francia'],
    ['city' => 'Londres', 'lat' => 51.5074, 'lon' => -0.1278, 'country' => 'Reino Unido'],
    ['city' => 'Roma', 'lat' => 41.9028, 'lon' => 12.4964, 'country' => 'Italia'],
    ['city' => 'Berlín', 'lat' => 52.5200, 'lon' => 13.4050, 'country' => 'Alemania'],
    ['city' => 'Lisboa', 'lat' => 38.7223, 'lon' => -9.1393, 'country' => 'Portugal'],
    ['city' => 'Nueva York', 'lat' => 40.7128, 'lon' => -74.0060, 'country' => 'Estados Unidos'],
    ['city' => 'México DF', 'lat' => 19.4326, 'lon' => -99.1332, 'country' => 'México'],
    ['city' => 'Buenos Aires', 'lat' => -34.6037, 'lon' => -58.3816, 'country' => 'Argentina'],
    ['city' => 'São Paulo', 'lat' => -23.5505, 'lon' => -46.6333, 'country' => 'Brasil'],
    ['city' => 'Lima', 'lat' => -12.0464, 'lon' => -77.0428, 'country' => 'Perú']
];

// Códigos de país ISO correctos
$country_codes = [
    'España' => 'ES',
    'Francia' => 'FR',
    'Reino Unido' => 'GB',
    'Italia' => 'IT',
    'Alemania' => 'DE',
    'Portugal' => 'PT',
    'Estados Unidos' => 'US',
    'México' => 'MX',
    'Argentina' => 'AR',
    'Brasil' => 'BR',
    'Perú' => 'PE'
];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';
    
    if ($action === 'generate_test') {
        try {
            // Obtener URLs existentes
            $stmt = $db->query("SELECT id FROM urls ORDER BY RAND() LIMIT 10");
            $urls = $stmt->fetchAll();
            
            if (empty($urls)) {
                $message = "Error: No hay URLs creadas. Crea algunas URLs primero.";
            } else {
                $count = 0;
                $todas_ciudades = array_merge($ciudades_espana, $ciudades_mundo);
                
                // Generar 50 clicks de prueba
                for ($i = 0; $i < 50; $i++) {
                    $url = $urls[array_rand($urls)];
                    $ciudad = $todas_ciudades[array_rand($todas_ciudades)];
                    
                    // Generar IP aleatoria (no local)
                    $ip = rand(1,255) . '.' . rand(0,255) . '.' . rand(0,255) . '.' . rand(0,255);
                    
                    // Obtener código de país correcto
                    $country_code = $country_codes[$ciudad['country']] ?? 'XX';
                    
                    $stmt = $db->prepare("
                        INSERT INTO click_stats (
                            url_id, clicked_at, ip_address, user_agent,
                            country, country_code, city, region,
                            latitude, longitude
                        ) VALUES (
                            ?, NOW() - INTERVAL RAND()*30 DAY, ?, ?,
                            ?, ?, ?, ?,
                            ?, ?
                        )
                    ");
                    
                    $stmt->execute([
                        $url['id'],
                        $ip,
                        'Mozilla/5.0 Test Browser',
                        $ciudad['country'],
                        $country_code,
                        $ciudad['city'],
                        $ciudad['city'],
                        $ciudad['lat'],
                        $ciudad['lon']
                    ]);
                    
                    $count++;
                }
                
                // Actualizar contadores de clicks
                $db->exec("
                    UPDATE urls u 
                    SET clicks = (SELECT COUNT(*) FROM click_stats WHERE url_id = u.id)
                ");
                
                $message = "✅ Se generaron $count clicks de prueba con geolocalización";
            }
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    }
    
    if ($action === 'fix_existing') {
        try {
            // Actualizar clicks existentes sin geolocalización
            $stmt = $db->query("
                SELECT id, ip_address 
                FROM click_stats 
                WHERE (latitude IS NULL OR longitude IS NULL)
                AND ip_address NOT IN ('127.0.0.1', '::1')
                LIMIT 100
            ");
            $clicks = $stmt->fetchAll();
            
            $updated = 0;
            foreach ($clicks as $click) {
                // Asignar ciudad aleatoria
                $ciudad = $ciudades_espana[array_rand($ciudades_espana)];
                
                $stmt = $db->prepare("
                    UPDATE click_stats 
                    SET country = ?, country_code = ?, city = ?, 
                        latitude = ?, longitude = ?
                    WHERE id = ?
                ");
                
                $stmt->execute([
                    $ciudad['country'],
                    'ES',  // Todos de España tienen código ES
                    $ciudad['city'],
                    $ciudad['lat'],
                    $ciudad['lon'],
                    $click['id']
                ]);
                
                $updated++;
            }
            
            $message = "✅ Se actualizaron $updated clicks con geolocalización";
        } catch (PDOException $e) {
            $message = "Error: " . $e->getMessage();
        }
    }
}

// Obtener estadísticas
$stats = [];
try {
    $stmt = $db->query("SELECT COUNT(*) as total FROM click_stats");
    $stats['total'] = $stmt->fetch()['total'];
    
    $stmt = $db->query("SELECT COUNT(*) as con_geo FROM click_stats WHERE latitude IS NOT NULL");
    $stats['con_geo'] = $stmt->fetch()['con_geo'];
    
    $stats['sin_geo'] = $stats['total'] - $stats['con_geo'];
} catch (PDOException $e) {
    $stats = ['total' => 0, 'con_geo' => 0, 'sin_geo' => 0];
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generar Datos de Geolocalización - Admin</title>
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
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
        }
        .card {
            background: white;
            border-radius: 10px;
            padding: 30px;
            margin-bottom: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-box {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 8px;
            text-align: center;
        }
        .stat-number {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        .stat-label {
            color: #666;
            font-size: 0.9em;
        }
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px;
            transition: all 0.3s;
        }
        .btn-primary {
            background: #667eea;
            color: white;
        }
        .btn-success {
            background: #28a745;
            color: white;
        }
        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.2);
        }
        .message {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        .message.success {
            background: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }
        .message.error {
            background: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }
        .back-link {
            display: inline-block;
            margin-bottom: 20px;
            color: #007bff;
            text-decoration: none;
        }
        .back-link:hover {
            text-decoration: underline;
        }
        .warning-box {
            background: #fff3cd;
            border: 1px solid #ffeaa7;
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        h3 {
            margin-bottom: 15px;
            color: #333;
        }
        .city-list {
            background: #f8f9fa;
            padding: 15px;
            border-radius: 8px;
            margin-top: 10px;
        }
        .city-list p {
            margin: 5px 0;
            line-height: 1.6;
        }
    </style>
</head>
<body>
    <?php include '../menu.php'; ?>
    
    <div class="header">
        <h1>🌍 Generador de Datos de Geolocalización</h1>
        <p>Herramienta para testing y demostración</p>
    </div>

    <div class="container">
        <a href="panel_simple.php" class="back-link">← Volver al Panel</a>
        <a href="mapa.php" class="back-link">🗺️ Ver Mapa</a>

        <?php if ($message): ?>
            <div class="message <?php echo strpos($message, '✅') !== false ? 'success' : 'error'; ?>">
                <?php echo $message; ?>
            </div>
        <?php endif; ?>

        <div class="card">
            <h3>📊 Estado Actual</h3>
            <div class="stats">
                <div class="stat-box">
                    <div class="stat-number"><?php echo $stats['total']; ?></div>
                    <div class="stat-label">Total Clicks</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number"><?php echo $stats['con_geo']; ?></div>
                    <div class="stat-label">Con Geolocalización</div>
                </div>
                <div class="stat-box">
                    <div class="stat-number"><?php echo $stats['sin_geo']; ?></div>
                    <div class="stat-label">Sin Geolocalización</div>
                </div>
            </div>
        </div>

        <div class="card">
            <h3>🔧 Acciones Disponibles</h3>
            
            <div class="warning-box">
                <strong>⚠️ Nota:</strong> Estas herramientas son para testing y demostración. 
                Los datos generados son ficticios pero útiles para probar el sistema.
            </div>

            <form method="POST" style="display: inline;">
                <input type="hidden" name="action" value="generate_test">
                <button type="submit" class="btn btn-primary">
                    🎲 Generar 50 Clicks de Prueba
                </button>
            </form>

            <form method="POST" style="display: inline;">
                <input type="hidden" name="action" value="fix_existing">
                <button type="submit" class="btn btn-success">
                    🔧 Añadir Geo a Clicks Existentes
                </button>
            </form>
        </div>

        <div class="card">
            <h3>📍 Ciudades Incluidas</h3>
            <div class="city-list">
                <p><strong>🇪🇸 España:</strong> Madrid, Barcelona, Valencia, Sevilla, Bilbao, Málaga, Zaragoza, Murcia, Palma, Las Palmas</p>
                <p><strong>🌍 Internacional:</strong> París (FR), Londres (GB), Roma (IT), Berlín (DE), Lisboa (PT), Nueva York (US), México DF (MX), Buenos Aires (AR), São Paulo (BR), Lima (PE)</p>
            </div>
        </div>
    </div>
</body>
</html>

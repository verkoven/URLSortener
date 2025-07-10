<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>Debug del sistema</h1>";

// Test 1: conf.php
echo "<h2>1. Probando conf.php:</h2>";
if (file_exists('conf.php')) {
    echo "✓ conf.php existe<br>";
    require_once 'conf.php';
    echo "✓ conf.php se cargó correctamente<br>";
} else {
    echo "✗ conf.php NO existe<br>";
}

// Test 2: Conexión BD
echo "<h2>2. Probando conexión BD:</h2>";
try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    echo "✓ Conexión exitosa<br>";
} catch(Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "<br>";
}

// Test 3: menu.php
echo "<h2>3. Probando menu.php:</h2>";
if (file_exists('menu.php')) {
    echo "✓ menu.php existe<br>";
} else {
    echo "✗ menu.php NO existe<br>";
}

echo "<h2>4. Constantes definidas:</h2>";
echo "DB_HOST: " . (defined('DB_HOST') ? 'SÍ' : 'NO') . "<br>";
echo "DB_NAME: " . (defined('DB_NAME') ? 'SÍ' : 'NO') . "<br>";
echo "BASE_URL: " . (defined('BASE_URL') ? 'SÍ' : 'NO') . "<br>";
?>

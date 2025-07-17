<?php
// config.php - Corregido para usuario real basado en username
error_reporting(E_ALL);
ini_set('display_errors', 1);

if (session_status() === PHP_SESSION_NONE) {
    ini_set('session.cookie_httponly', 1);
    ini_set('session.use_only_cookies', 1);
    session_start();
}

require_once '../conf.php';

define('APP_NAME', 'Gestor de URLs Cortas');
define('APP_VERSION', '2.0.0');

if (!isset($pdo)) {
    try {
        $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    } catch (PDOException $e) {
        error_log("❌ Error DB: " . $e->getMessage());
        die("Error de conexión a base de datos");
    }
}

// Función getCurrentUserId CORREGIDA - Usar username en lugar de user_id
if (!function_exists('getCurrentUserId')) {
    function getCurrentUserId() {
        global $pdo;
        
        // Priorizar username sobre user_id para evitar confusiones
        if (isset($_SESSION['username']) && !empty($_SESSION['username'])) {
            $username = $_SESSION['username'];
            
            try {
                $stmt = $pdo->prepare("SELECT id, username FROM users WHERE username = ? AND status = 'active'");
                $stmt->execute([$username]);
                $user = $stmt->fetch();
                
                if ($user) {
                    error_log("✅ Usuario encontrado por username: {$user['username']} (ID: {$user['id']})");
                    return $user['id'];
                } else {
                    error_log("❌ Username '{$username}' no encontrado o inactivo");
                }
            } catch (Exception $e) {
                error_log("❌ Error buscando por username: " . $e->getMessage());
            }
        }
        
        // Fallback: verificar user_id solo si username no existe
        if (isset($_SESSION['user_id']) && !empty($_SESSION['user_id'])) {
            $user_id = $_SESSION['user_id'];
            
            try {
                $stmt = $pdo->prepare("SELECT id, username FROM users WHERE id = ? AND status = 'active'");
                $stmt->execute([$user_id]);
                $user = $stmt->fetch();
                
                if ($user) {
                    error_log("⚠️ Usuario encontrado por user_id: {$user['username']} (ID: {$user['id']})");
                    return $user['id'];
                }
            } catch (Exception $e) {
                error_log("❌ Error verificando user_id: " . $e->getMessage());
            }
        }
        
        error_log("❌ No se pudo determinar usuario autenticado");
        return null;
    }
}

if (!function_exists('getCurrentUserInfo')) {
    function getCurrentUserInfo() {
        global $pdo;
        
        $user_id = getCurrentUserId();
        if (!$user_id) return null;
        
        try {
            $stmt = $pdo->prepare("SELECT id, username, email FROM users WHERE id = ? AND status = 'active'");
            $stmt->execute([$user_id]);
            $result = $stmt->fetch();
            
            error_log("✅ getCurrentUserInfo: " . json_encode($result));
            return $result;
        } catch (Exception $e) {
            error_log("❌ Error obteniendo info usuario: " . $e->getMessage());
            return null;
        }
    }
}

// Verificar autenticación
$current_user_id = getCurrentUserId();

error_log("🎯 Usuario actual determinado: " . ($current_user_id ?: 'NULL'));

if (!$current_user_id) {
    error_log("❌ Redirecting to login - no authenticated user");
    header('Location: ../login.php');
    exit;
}

// Actualizar sesión con el ID correcto
$_SESSION['current_user_id'] = $current_user_id;

// Log final
$userInfo = getCurrentUserInfo();
error_log("✅ Sistema iniciado para: {$userInfo['username']} (ID: {$current_user_id})");
?>

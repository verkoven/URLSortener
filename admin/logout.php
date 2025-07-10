<?php
session_start();
require_once '../conf.php';

// Forzar HTTPS
forceHttps();

// Limpiar la sesión completamente
$_SESSION = array();

// Eliminar la cookie de sesión
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(session_name(), '', time() - 42000,
        $params["path"], $params["domain"],
        $params["secure"], $params["httponly"]
    );
}

// Destruir la sesión
session_destroy();

// Configurar headers de seguridad
setSecurityHeaders();

// Redirigir al login con mensaje
header('Location: login.php?logout=1');
exit();
?>

<?php
session_start();
require_once '../conf.php';

header('Content-Type: application/json');

// Verificar si el usuario está logueado
if (!isset($_SESSION['admin_logged_in']) || $_SESSION['admin_logged_in'] !== true) {
    die(json_encode(['success' => false, 'message' => 'No autorizado']));
}

$domain_id = (int)($_POST['domain_id'] ?? 0);
$user_id = $_SESSION['user_id'];

if (!$domain_id) {
    die(json_encode(['success' => false, 'message' => 'ID de dominio inválido']));
}

try {
    $db = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Obtener información del dominio
    $stmt = $db->prepare("SELECT * FROM custom_domains WHERE id = ? AND user_id = ?");
    $stmt->execute([$domain_id, $user_id]);
    $domain = $stmt->fetch();
    
    if (!$domain) {
        die(json_encode(['success' => false, 'message' => 'Dominio no encontrado o no tienes permisos']));
    }
    
    $verified = false;
    $method = '';
    $error_details = [];
    
    // 1. Intentar verificación por archivo
    $verification_url = "http://" . $domain['domain'] . "/acortador-verify-" . $domain['verification_token'] . ".txt";
    
    // Usar cURL para más control
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $verification_url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
    curl_setopt($ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curl_error = curl_error($ch);
    curl_close($ch);
    
    if ($http_code == 200) {
        // Verificar que el contenido contiene el token
        if (strpos($response, $domain['verification_token']) !== false) {
            $verified = true;
            $method = 'file';
        } else {
            $error_details[] = "Archivo encontrado pero no contiene el token correcto";
        }
    } else {
        $error_details[] = "Archivo no encontrado (HTTP $http_code)";
        if ($curl_error) {
            $error_details[] = "Error cURL: $curl_error";
        }
    }
    
    // 2. Si no se verificó por archivo, intentar por TXT DNS
    if (!$verified) {
        $txt_domain = '_acortador.' . $domain['domain'];
        
        // Intentar obtener registros TXT
        $txt_records = @dns_get_record($txt_domain, DNS_TXT);
        
        if ($txt_records === false) {
            $error_details[] = "No se pudieron obtener registros DNS para $txt_domain";
        } else if (empty($txt_records)) {
            $error_details[] = "No se encontraron registros TXT en $txt_domain";
        } else {
            $found_txt = false;
            foreach ($txt_records as $record) {
                if (isset($record['txt'])) {
                    if ($record['txt'] === $domain['verification_token']) {
                        $verified = true;
                        $method = 'dns_txt';
                        break;
                    } else {
                        $found_txt = true;
                        $error_details[] = "Registro TXT encontrado pero no coincide: " . substr($record['txt'], 0, 20) . "...";
                    }
                }
            }
            if (!$found_txt && !$verified) {
                $error_details[] = "No se encontró el registro TXT con el token";
            }
        }
    }
    
    // 3. Verificar CNAME como método informativo
    if (!$verified) {
        $cname_records = @dns_get_record($domain['domain'], DNS_CNAME);
        $a_records = @dns_get_record($domain['domain'], DNS_A);
        
        $dns_configured = false;
        
        if ($cname_records) {
            foreach ($cname_records as $record) {
                if (isset($record['target'])) {
                    $target = rtrim($record['target'], '.');
                    if (strcasecmp($target, $_SERVER['HTTP_HOST']) == 0) {
                        $dns_configured = true;
                        $error_details[] = "CNAME configurado correctamente hacia " . $_SERVER['HTTP_HOST'];
                    } else {
                        $error_details[] = "CNAME apunta a: " . $target;
                    }
                }
            }
        }
        
        if ($a_records && !empty($a_records)) {
            $server_ip = gethostbyname($_SERVER['HTTP_HOST']);
            foreach ($a_records as $record) {
                if (isset($record['ip'])) {
                    if ($record['ip'] == $server_ip) {
                        $dns_configured = true;
                        $error_details[] = "Registro A configurado correctamente";
                    } else {
                        $error_details[] = "Registro A apunta a: " . $record['ip'];
                    }
                }
            }
        }
        
        if ($dns_configured) {
            $error_details[] = "DNS configurado pero falta verificación de propiedad (archivo o TXT)";
        }
    }
    
    // Resultado final
    if ($verified) {
        // Actualizar el dominio como verificado
        $stmt = $db->prepare("UPDATE custom_domains SET status = 'active', verified_at = NOW(), verification_method = ? WHERE id = ?");
        $stmt->execute([$method, $domain_id]);
        
        $method_text = ($method === 'file') ? 'archivo' : 'registro TXT DNS';
        
        echo json_encode([
            'success' => true, 
            'message' => "✅ Dominio verificado correctamente mediante $method_text",
            'method' => $method
        ]);
    } else {
        // Construir mensaje de error detallado
        $message = "❌ No se pudo verificar el dominio.\n\n";
        $message .= "Detalles:\n";
        foreach ($error_details as $detail) {
            $message .= "• $detail\n";
        }
        
        $message .= "\nAsegúrate de:\n";
        $message .= "1. Subir el archivo de verificación a la raíz del dominio\n";
        $message .= "2. O crear el registro TXT en _acortador." . $domain['domain'] . "\n";
        $message .= "3. Que el DNS apunte correctamente a este servidor";
        
        echo json_encode([
            'success' => false, 
            'message' => $message,
            'details' => $error_details,
            'verification_url' => $verification_url,
            'expected_token' => $domain['verification_token']
        ]);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false, 
        'message' => 'Error del sistema: ' . $e->getMessage()
    ]);
}
?>

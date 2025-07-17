<?php
// api.php - API completa usando usuario real
ob_start();
header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST');
header('Access-Control-Allow-Headers: Content-Type');

error_reporting(E_ALL);
ini_set('display_errors', 0);

try {
    require_once 'config.php';
    require_once 'functions.php';
    
    ob_clean();
    
    // Usar usuario real autenticado
    $user_id = getCurrentUserId();
    
    if (!$user_id) {
        echo json_encode([
            'success' => false, 
            'message' => 'Usuario no autenticado', 
            'redirect' => '../login.php'
        ]);
        exit;
    }
    
    $action = $_GET['action'] ?? $_POST['action'] ?? '';
    error_log("🔥 API Action: {$action} - User: {$user_id}");
    
    switch ($action) {
        case 'get_urls':
            try {
                $category = $_GET['category'] ?? null;
                $urls = getUserUrls($user_id, $category);
                
                error_log("📊 get_urls: " . count($urls) . " URLs found for user {$user_id}");
                
                echo json_encode([
                    'success' => true, 
                    'urls' => $urls,
                    'count' => count($urls),
                    'user_id' => $user_id
                ]);
                
            } catch (Exception $e) {
                error_log("❌ get_urls error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error al obtener URLs: ' . $e->getMessage()]);
            }
            break;
            
        case 'add_url':
            try {
                $shortUrl = $_POST['shortUrl'] ?? '';
                $title = $_POST['title'] ?? '';
                $category = $_POST['category'] ?? null;
                $notes = $_POST['notes'] ?? null;
                
                error_log("➕ add_url: {$shortUrl} - {$title} - User: {$user_id}");
                
                if (!$shortUrl || !$title) {
                    echo json_encode(['success' => false, 'message' => 'Datos incompletos']);
                    break;
                }
                
                $result = addUrlToManager($user_id, $shortUrl, $title, $category, $notes);
                error_log("➕ add_url result: " . json_encode($result));
                
                echo json_encode($result);
                
            } catch (Exception $e) {
                error_log("❌ add_url error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error al agregar URL: ' . $e->getMessage()]);
            }
            break;
            
        case 'remove_url':
            try {
                $url_id = $_POST['url_id'] ?? 0;
                
                error_log("➖ remove_url: ID {$url_id} - User: {$user_id}");
                
                if (!$url_id) {
                    echo json_encode(['success' => false, 'message' => 'ID de URL no válido']);
                    break;
                }
                
                $result = removeUrlFromManager($user_id, $url_id);
                error_log("➖ remove_url result: " . json_encode($result));
                
                echo json_encode($result);
                
            } catch (Exception $e) {
                error_log("❌ remove_url error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error al eliminar URL: ' . $e->getMessage()]);
            }
            break;
            
        case 'update_url':
            try {
                $url_id = $_POST['url_id'] ?? 0;
                $title = $_POST['title'] ?? '';
                $category = $_POST['category'] ?? null;
                $notes = $_POST['notes'] ?? null;
                
                error_log("✏️ update_url: ID {$url_id} - {$title} - User: {$user_id}");
                
                if (!$url_id || !$title) {
                    echo json_encode(['success' => false, 'message' => 'Datos incompletos']);
                    break;
                }
                
                $result = updateUrlInManager($user_id, $url_id, $title, $category, $notes);
                error_log("✏️ update_url result: " . json_encode($result));
                
                echo json_encode($result);
                
            } catch (Exception $e) {
                error_log("❌ update_url error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error al actualizar URL: ' . $e->getMessage()]);
            }
            break;
            
        case 'sync_system':
            try {
                error_log("🔄 sync_system: Starting sync for user {$user_id}");
                
                $result = syncWithMainSystem($user_id);
                error_log("🔄 sync_system result: " . json_encode($result));
                
                echo json_encode($result);
                
            } catch (Exception $e) {
                error_log("❌ sync_system error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error en sincronización: ' . $e->getMessage()]);
            }
            break;
            
        case 'export_json':
            try {
                error_log("📤 export_json: Starting export for user {$user_id}");
                
                $data = exportToJson($user_id);
                error_log("📤 export_json: " . count($data['urls']) . " URLs exported");
                
                ob_clean();
                
                header('Content-Type: application/json; charset=UTF-8');
                header('Content-Disposition: attachment; filename="urls_backup_' . date('Y-m-d') . '.json"');
                header('Cache-Control: no-cache, must-revalidate');
                
                echo json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
                exit;
                
            } catch (Exception $e) {
                error_log("❌ export_json error: " . $e->getMessage());
                ob_clean();
                echo json_encode(['success' => false, 'message' => 'Error al exportar JSON: ' . $e->getMessage()]);
            }
            break;
            
        case 'export_bookmarks':
            try {
                error_log("🌐 export_bookmarks: Starting export for user {$user_id}");
                
                $urls = getUserUrls($user_id);
                error_log("🌐 export_bookmarks: " . count($urls) . " URLs found");
                
                if (empty($urls)) {
                    $html = '<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!--This is an automatically generated file.-->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>
    <DT><H3>Sin URLs</H3>
    <DL><p>
        <DT><A HREF="#">No se encontraron URLs para exportar</A>
        <DT><A HREF="../">Ir al acortador</A>
    </DL><p>
</DL><p>';
                    
                    error_log("🌐 export_bookmarks: No URLs found for user {$user_id}");
                    
                } else {
                    $html = convertToBookmarksHTML($urls);
                    error_log("🌐 export_bookmarks: HTML generated, length: " . strlen($html));
                }
                
                ob_clean();
                
                header('Content-Type: text/html; charset=UTF-8');
                header('Content-Disposition: attachment; filename="bookmarks_' . date('Y-m-d') . '.html"');
                header('Cache-Control: no-cache, must-revalidate');
                
                echo $html;
                exit;
                
            } catch (Exception $e) {
                error_log("❌ export_bookmarks error: " . $e->getMessage());
                ob_clean();
                echo "Error al exportar favoritos: " . $e->getMessage();
            }
            break;
            
        case 'import_json':
            try {
                error_log("📥 import_json: Starting import for user {$user_id}");
                
                if (!isset($_FILES['json_file'])) {
                    echo json_encode(['success' => false, 'message' => 'No se subió archivo']);
                    break;
                }
                
                $file = $_FILES['json_file'];
                error_log("📥 import_json: File uploaded - " . $file['name'] . " (" . $file['size'] . " bytes)");
                
                if ($file['error'] !== UPLOAD_ERR_OK) {
                    echo json_encode(['success' => false, 'message' => 'Error al subir archivo: ' . $file['error']]);
                    break;
                }
                
                if ($file['size'] > 5000000) {
                    echo json_encode(['success' => false, 'message' => 'Archivo muy grande (máx 5MB)']);
                    break;
                }
                
                $fileContent = file_get_contents($file['tmp_name']);
                if (!$fileContent) {
                    echo json_encode(['success' => false, 'message' => 'No se pudo leer el archivo']);
                    break;
                }
                
                error_log("📥 import_json: File content length: " . strlen($fileContent));
                
                $jsonData = json_decode($fileContent, true);
                if (!$jsonData) {
                    $jsonError = json_last_error_msg();
                    error_log("❌ import_json: JSON error: " . $jsonError);
                    echo json_encode(['success' => false, 'message' => 'JSON inválido: ' . $jsonError]);
                    break;
                }
                
                $result = importFromJson($user_id, $jsonData);
                error_log("📥 import_json result: " . json_encode($result));
                
                echo json_encode($result);
                
            } catch (Exception $e) {
                error_log("❌ import_json error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error al importar: ' . $e->getMessage()]);
            }
            break;
            
        case 'clear_manager':
            try {
                error_log("🗑️ clear_manager: Clearing manager for user {$user_id}");
                
                $stmt = $pdo->prepare("DELETE FROM user_urls WHERE user_id = :user_id");
                $result = $stmt->execute([':user_id' => $user_id]);
                
                $deletedCount = $stmt->rowCount();
                error_log("🗑️ clear_manager: Deleted {$deletedCount} URLs for user {$user_id}");
                
                if ($result) {
                    echo json_encode(['success' => true, 'message' => "Gestor limpiado ({$deletedCount} URLs eliminadas)"]);
                } else {
                    echo json_encode(['success' => false, 'message' => 'Error al limpiar gestor']);
                }
                
            } catch (Exception $e) {
                error_log("❌ clear_manager error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error al limpiar: ' . $e->getMessage()]);
            }
            break;
            
        case 'get_stats':
            try {
                $stats = getStats($user_id);
                error_log("📊 get_stats for user {$user_id}: " . json_encode($stats));
                
                echo json_encode(['success' => true, 'stats' => $stats]);
                
            } catch (Exception $e) {
                error_log("❌ get_stats error: " . $e->getMessage());
                echo json_encode(['success' => false, 'message' => 'Error al obtener estadísticas: ' . $e->getMessage()]);
            }
            break;
            
        case 'test_auth':
            try {
                $userInfo = getCurrentUserInfo();
                echo json_encode([
                    'success' => true,
                    'user_id' => $user_id,
                    'user_info' => $userInfo,
                    'session' => $_SESSION
                ]);
            } catch (Exception $e) {
                echo json_encode(['success' => false, 'message' => 'Error: ' . $e->getMessage()]);
            }
            break;
            
        default:
            error_log("❌ Unknown action: {$action}");
            echo json_encode(['success' => false, 'message' => 'Acción no válida: ' . $action]);
    }
    
} catch (Exception $e) {
    error_log("💥 API Fatal Error: " . $e->getMessage());
    ob_clean();
    echo json_encode([
        'success' => false, 
        'message' => 'Error del servidor: ' . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}

ob_end_flush();
exit;
?>

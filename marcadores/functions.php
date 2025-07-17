<?php
// functions.php - Con exportación mejorada que incluye URL destino

function getDomainFromId($domain_id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("SELECT domain FROM custom_domains WHERE id = ?");
        $stmt->execute([$domain_id]);
        $result = $stmt->fetch();
        
        return $result ? $result['domain'] : '0ln.eu';
    } catch (Exception $e) {
        error_log("Error getting domain: " . $e->getMessage());
        return '0ln.eu';
    }
}

function getUserUrls($user_id, $category = null) {
    global $pdo;
    
    try {
        $sql = "SELECT 
                    u.id,
                    u.short_code,
                    u.domain_id,
                    u.original_url,
                    u.title as original_title,
                    u.created_at as url_created,
                    u.clicks,
                    u.user_id,
                    cd.domain,
                    uu.title as custom_title,
                    uu.category,
                    uu.favicon,
                    uu.notes,
                    uu.created_at as added_to_manager
                FROM urls u
                LEFT JOIN custom_domains cd ON u.domain_id = cd.id
                LEFT JOIN user_urls uu ON (u.id = uu.url_id)
                WHERE u.user_id = :user_id 
                AND u.active = 1";
        
        $params = [':user_id' => $user_id];
        
        if ($category) {
            $sql .= " AND uu.category = :category";
            $params[':category'] = $category;
        }
        
        $sql .= " ORDER BY u.created_at DESC";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        return array_map(function($row) {
            $domain = $row['domain'] ?? '0ln.eu';
            
            return [
                'id' => $row['id'],
                'short_url' => 'https://' . $domain . '/' . $row['short_code'],
                'short_code' => $row['short_code'],
                'domain' => $domain,
                'domain_id' => $row['domain_id'],
                'title' => $row['custom_title'] ?: $row['original_title'] ?: 'Sin título',
                'original_url' => $row['original_url'],
                'favicon' => $row['favicon'] ?: generateFavicon($row['original_url']),
                'category' => $row['category'],
                'notes' => $row['notes'],
                'created_at' => $row['url_created'],
                'added_to_manager' => $row['added_to_manager'],
                'clicks' => $row['clicks'] ?: 0,
                'in_manager' => !is_null($row['added_to_manager'])
            ];
        }, $results);
        
    } catch (Exception $e) {
        error_log("Error en getUserUrls: " . $e->getMessage());
        return [];
    }
}

function importFromJson($user_id, $jsonData) {
    global $pdo;
    
    $imported = 0;
    $errors = [];
    
    $urls = [];
    if (isset($jsonData['urls']) && is_array($jsonData['urls'])) {
        $urls = $jsonData['urls'];
    } elseif (is_array($jsonData)) {
        $urls = $jsonData;
    } else {
        return ['success' => false, 'message' => 'Formato JSON inválido'];
    }
    
    if (empty($urls)) {
        return ['success' => false, 'message' => 'No se encontraron URLs en el JSON'];
    }
    
    foreach ($urls as $index => $url) {
        try {
            $shortUrl = $url['shortUrl'] ?? $url['short_url'] ?? null;
            $title = $url['title'] ?? $url['custom_title'] ?? 'Importado';
            $category = $url['category'] ?? null;
            $notes = $url['notes'] ?? null;
            
            $originalUrl = $url['originalUrl'] ?? $url['original_url'] ?? null;
            $date = $url['date'] ?? $url['created_at'] ?? null;
            
            if (!$shortUrl) {
                $errors[] = "URL #{$index}: Sin URL válida";
                continue;
            }
            
            $shortCode = extractShortCode($shortUrl);
            if (!$shortCode) {
                $errors[] = "URL #{$index}: Código corto inválido para {$shortUrl}";
                continue;
            }
            
            $stmt = $pdo->prepare("
                SELECT id, original_url, user_id 
                FROM urls 
                WHERE short_code = :short_code 
                AND user_id = :user_id 
                AND active = 1
            ");
            $stmt->execute([':short_code' => $shortCode, ':user_id' => $user_id]);
            $existingUrl = $stmt->fetch();
            
            if (!$existingUrl) {
                $errors[] = "URL #{$index}: Código '{$shortCode}' no existe en tu cuenta activa";
                continue;
            }
            
            $stmt = $pdo->prepare("SELECT id FROM user_urls WHERE user_id = :user_id AND url_id = :url_id");
            $stmt->execute([':user_id' => $user_id, ':url_id' => $existingUrl['id']]);
            
            if ($stmt->fetch()) {
                $errors[] = "URL #{$index}: '{$shortCode}' ya está en el gestor";
                continue;
            }
            
            $favicon = generateFavicon($existingUrl['original_url']);
            
            $stmt = $pdo->prepare("
                INSERT INTO user_urls (user_id, url_id, title, category, favicon, notes, created_at) 
                VALUES (:user_id, :url_id, :title, :category, :favicon, :notes, :created_at)
            ");
            
            $createdAt = $date ? date('Y-m-d H:i:s', strtotime($date)) : date('Y-m-d H:i:s');
            
            if ($stmt->execute([
                ':user_id' => $user_id,
                ':url_id' => $existingUrl['id'],
                ':title' => $title,
                ':category' => $category,
                ':favicon' => $favicon,
                ':notes' => $notes,
                ':created_at' => $createdAt
            ])) {
                $imported++;
            } else {
                $errors[] = "URL #{$index}: Error al insertar en base de datos";
            }
            
        } catch (Exception $e) {
            $errors[] = "URL #{$index}: Error - " . $e->getMessage();
        }
    }
    
    return [
        'success' => $imported > 0,
        'imported' => $imported,
        'total_processed' => count($urls),
        'errors' => $errors,
        'message' => $imported > 0 ? 
            "{$imported} URLs importadas de " . count($urls) . " procesadas" :
            "No se importaron URLs. Verifica que sean de tu cuenta activa."
    ];
}

function extractShortCode($url) {
    $parsed = parse_url($url);
    if (!$parsed) return null;
    
    $path = trim($parsed['path'], '/');
    $parts = explode('/', $path);
    $shortCode = end($parts);
    
    return !empty($shortCode) ? $shortCode : null;
}

function exportToJson($user_id) {
    $urls = getUserUrls($user_id);
    
    $exportData = [
        'exported_at' => date('c'),
        'user_id' => $user_id,
        'total' => count($urls),
        'urls' => array_map(function($url) {
            return [
                'shortUrl' => $url['short_url'],
                'short_code' => $url['short_code'],
                'title' => $url['title'],
                'originalUrl' => $url['original_url'],
                'original_url' => $url['original_url'],
                'favicon' => $url['favicon'],
                'category' => $url['category'],
                'notes' => $url['notes'],
                'date' => $url['created_at'],
                'created_at' => $url['created_at'],
                'clicks' => $url['clicks'],
                'domain' => $url['domain'],
                'domain_id' => $url['domain_id']
            ];
        }, $urls)
    ];
    
    return $exportData;
}

// 🎯 FUNCIÓN MEJORADA CON URL DESTINO
function convertToBookmarksHTML($urls) {
    $html = '<!DOCTYPE NETSCAPE-Bookmark-file-1>
<!--This is an automatically generated file.-->
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
<TITLE>Bookmarks</TITLE>
<H1>Bookmarks</H1>
<DL><p>';

    $categorized = [];
    foreach ($urls as $url) {
        $category = $url['category'] ?: 'URLs Cortas';
        if (!isset($categorized[$category])) {
            $categorized[$category] = [];
        }
        $categorized[$category][] = $url;
    }
    
    foreach ($categorized as $category => $categoryUrls) {
        $addDate = time();
        $html .= "\n    <DT><H3 ADD_DATE=\"{$addDate}\" LAST_MODIFIED=\"{$addDate}\">" . htmlspecialchars($category) . "</H3>";
        $html .= "\n    <DL><p>";
        
        foreach ($categoryUrls as $url) {
            $addDate = strtotime($url['created_at']);
            
            // 🎯 MEJORAR TÍTULO CON URL DESTINO
            $originalDomain = parse_url($url['original_url'])['host'] ?? 'Enlace';
            $originalDomain = str_replace('www.', '', $originalDomain);
            
            // Título mejorado: "Dominio - código → URL completa"
            $enhancedTitle = ucfirst($originalDomain) . ' - ' . $url['short_code'] . ' → ' . $url['original_url'];
            
            $title = htmlspecialchars($enhancedTitle);
            $shortUrl = htmlspecialchars($url['short_url']);
            
            $html .= "\n        <DT><A HREF=\"{$shortUrl}\" ADD_DATE=\"{$addDate}\">{$title}</A>";
            
            // 🎯 AGREGAR DESCRIPCIÓN CON MÁS DETALLES
            $description = "🔗 URL corta: {$url['short_url']}\n📍 Destino: {$url['original_url']}\n📊 Clics: {$url['clicks']}\n📅 Creado: {$url['created_at']}";
            if ($url['notes']) {
                $description .= "\n📝 Notas: {$url['notes']}";
            }
            
            $html .= "\n        <DD>" . htmlspecialchars($description);
        }
        
        $html .= "\n    </DL><p>";
    }
    
    $html .= "\n</DL><p>";
    
    return $html;
}

function generateFavicon($url) {
    if (!$url) return null;
    
    $parsed = parse_url($url);
    if (!$parsed || !isset($parsed['host'])) return null;
    
    return "https://www.google.com/s2/favicons?domain=" . $parsed['host'];
}

function addUrlToManager($user_id, $shortUrl, $title, $category = null, $notes = null) {
    global $pdo;
    
    try {
        $shortCode = extractShortCode($shortUrl);
        
        if (!$shortCode) {
            return ['success' => false, 'message' => 'URL corta inválida'];
        }
        
        $stmt = $pdo->prepare("
            SELECT id, original_url, user_id 
            FROM urls 
            WHERE short_code = :short_code 
            AND user_id = :user_id 
            AND active = 1
        ");
        $stmt->execute([':short_code' => $shortCode, ':user_id' => $user_id]);
        $url = $stmt->fetch();
        
        if (!$url) {
            return ['success' => false, 'message' => 'URL corta no encontrada en tu cuenta activa'];
        }
        
        $stmt = $pdo->prepare("SELECT id FROM user_urls WHERE url_id = :url_id");
        $stmt->execute([':url_id' => $url['id']]);
        
        if ($stmt->fetch()) {
            return ['success' => false, 'message' => 'Esta URL ya está en el gestor'];
        }
        
        $favicon = generateFavicon($url['original_url']);
        
        $stmt = $pdo->prepare("
            INSERT INTO user_urls (user_id, url_id, title, category, favicon, notes, created_at) 
            VALUES (:user_id, :url_id, :title, :category, :favicon, :notes, NOW())
        ");
        
        $result = $stmt->execute([
            ':user_id' => $user_id,
            ':url_id' => $url['id'],
            ':title' => $title,
            ':category' => $category,
            ':favicon' => $favicon,
            ':notes' => $notes
        ]);
        
        return ['success' => $result, 'message' => $result ? 'URL agregada al gestor' : 'Error al agregar URL'];
        
    } catch (Exception $e) {
        error_log("Error en addUrlToManager: " . $e->getMessage());
        return ['success' => false, 'message' => 'Error del servidor'];
    }
}

function removeUrlFromManager($user_id, $url_id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("DELETE FROM user_urls WHERE url_id = :url_id AND user_id = :user_id");
        $result = $stmt->execute([':url_id' => $url_id, ':user_id' => $user_id]);
        
        return ['success' => $result, 'message' => $result ? 'URL eliminada del gestor' : 'Error al eliminar'];
        
    } catch (Exception $e) {
        error_log("Error en removeUrlFromManager: " . $e->getMessage());
        return ['success' => false, 'message' => 'Error del servidor'];
    }
}

function updateUrlInManager($user_id, $url_id, $title, $category = null, $notes = null) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("
            UPDATE user_urls 
            SET title = :title, category = :category, notes = :notes, updated_at = NOW()
            WHERE user_id = :user_id AND url_id = :url_id
        ");
        
        $result = $stmt->execute([
            ':user_id' => $user_id,
            ':url_id' => $url_id,
            ':title' => $title,
            ':category' => $category,
            ':notes' => $notes
        ]);
        
        return ['success' => $result, 'message' => $result ? 'URL actualizada' : 'Error al actualizar'];
        
    } catch (Exception $e) {
        error_log("Error en updateUrlInManager: " . $e->getMessage());
        return ['success' => false, 'message' => 'Error del servidor'];
    }
}

function syncWithMainSystem($user_id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("
            SELECT u.id, u.short_code, u.original_url, u.title, u.created_at
            FROM urls u
            LEFT JOIN user_urls uu ON u.id = uu.url_id
            WHERE u.user_id = :user_id 
            AND u.active = 1
            AND uu.id IS NULL
            ORDER BY u.created_at DESC
        ");
        
        $stmt->execute([':user_id' => $user_id]);
        $urlsToSync = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $synced = 0;
        
        foreach ($urlsToSync as $url) {
            $favicon = generateFavicon($url['original_url']);
            
            $stmt = $pdo->prepare("
                INSERT INTO user_urls (user_id, url_id, title, favicon, created_at) 
                VALUES (:user_id, :url_id, :title, :favicon, :created_at)
            ");
            
            if ($stmt->execute([
                ':user_id' => $user_id,
                ':url_id' => $url['id'],
                ':title' => $url['title'] ?: 'Sincronizado',
                ':favicon' => $favicon,
                ':created_at' => $url['created_at']
            ])) {
                $synced++;
            }
        }
        
        return ['success' => true, 'synced' => $synced, 'message' => "{$synced} URLs sincronizadas"];
        
    } catch (Exception $e) {
        error_log("Error en syncWithMainSystem: " . $e->getMessage());
        return ['success' => false, 'message' => 'Error en sincronización'];
    }
}

function getStats($user_id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM user_urls WHERE user_id = :user_id");
        $stmt->execute([':user_id' => $user_id]);
        $managerTotal = $stmt->fetch()['total'];
        
        $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM urls WHERE user_id = :user_id AND active = 1");
        $stmt->execute([':user_id' => $user_id]);
        $systemTotal = $stmt->fetch()['total'];
        
        $stmt = $pdo->prepare("SELECT category, COUNT(*) as count FROM user_urls WHERE user_id = :user_id GROUP BY category");
        $stmt->execute([':user_id' => $user_id]);
        $categories = $stmt->fetchAll(PDO::FETCH_KEY_PAIR);
        
        return [
            'manager_total' => $managerTotal,
            'system_total' => $systemTotal,
            'sync_pending' => $systemTotal - $managerTotal,
            'categories' => $categories
        ];
        
    } catch (Exception $e) {
        error_log("Error en getStats: " . $e->getMessage());
        return [
            'manager_total' => 0,
            'system_total' => 0,
            'sync_pending' => 0,
            'categories' => []
        ];
    }
}

function getOriginalUrlInfo($shortUrl) {
    $info = ['original_url' => null, 'favicon' => null];
    
    try {
        $url = parse_url($shortUrl);
        $domain = $url['host'];
        $path = trim($url['path'], '/');
        
        $apiUrl = "https://{$domain}/api/info.php?code={$path}";
        
        $context = stream_context_create([
            'http' => [
                'timeout' => 5,
                'method' => 'GET'
            ]
        ]);
        
        $response = @file_get_contents($apiUrl, false, $context);
        
        if ($response) {
            $data = json_decode($response, true);
            if ($data && isset($data['original_url'])) {
                $info['original_url'] = $data['original_url'];
                $info['favicon'] = $data['favicon'] ?? null;
            }
        }
        
        if (!$info['favicon'] && $info['original_url']) {
            $originalDomain = parse_url($info['original_url'])['host'];
            $info['favicon'] = "https://www.google.com/s2/favicons?domain={$originalDomain}";
        }
        
    } catch (Exception $e) {
        error_log("Error obteniendo info de URL: " . $e->getMessage());
    }
    
    return $info;
}

function isPublicUrl($url_id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("SELECT is_public FROM urls WHERE id = :id");
        $stmt->execute([':id' => $url_id]);
        $result = $stmt->fetch();
        
        return $result ? (bool)$result['is_public'] : false;
    } catch (Exception $e) {
        return false;
    }
}

function testFunction() {
    return "Functions.php cargado correctamente - " . date('Y-m-d H:i:s');
}

function clearManager($user_id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("DELETE FROM user_urls WHERE user_id = :user_id");
        $result = $stmt->execute([':user_id' => $user_id]);
        
        return ['success' => $result, 'message' => $result ? 'Gestor limpiado' : 'Error al limpiar'];
        
    } catch (Exception $e) {
        error_log("Error en clearManager: " . $e->getMessage());
        return ['success' => false, 'message' => 'Error del servidor'];
    }
}

function getDomainStats($user_id) {
    global $pdo;
    
    try {
        $stmt = $pdo->prepare("
            SELECT 
                u.domain_id,
                cd.domain,
                COUNT(*) as count
            FROM urls u
            LEFT JOIN custom_domains cd ON u.domain_id = cd.id
            WHERE u.user_id = :user_id AND u.active = 1
            GROUP BY u.domain_id, cd.domain
            ORDER BY count DESC
        ");
        
        $stmt->execute([$user_id]);
        $results = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $stats = [];
        foreach ($results as $row) {
            $domain = $row['domain'] ?? 'Sin dominio';
            $stats[$domain] = $row['count'];
        }
        
        return $stats;
        
    } catch (Exception $e) {
        error_log("Error en getDomainStats: " . $e->getMessage());
        return [];
    }
}

function validateShortUrl($shortUrl) {
    if (!$shortUrl) return false;
    
    $parsed = parse_url($shortUrl);
    if (!$parsed || !isset($parsed['host']) || !isset($parsed['path'])) {
        return false;
    }
    
    $shortCode = extractShortCode($shortUrl);
    return !empty($shortCode);
}

// Solo definir funciones que NO existan en conf.php
if (!function_exists('formatBytes')) {
    function formatBytes($bytes, $precision = 2) {
        $units = array('B', 'KB', 'MB', 'GB', 'TB');
        
        for ($i = 0; $bytes > 1024 && $i < count($units) - 1; $i++) {
            $bytes /= 1024;
        }
        
        return round($bytes, $precision) . ' ' . $units[$i];
    }
}

if (!function_exists('logActivity')) {
    function logActivity($user_id, $action, $details = null) {
        error_log("USER {$user_id}: {$action}" . ($details ? " - {$details}" : ""));
    }
}

error_log("✅ functions.php completo cargado - " . date('Y-m-d H:i:s'));
?>

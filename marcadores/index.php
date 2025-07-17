<?php
// index.php - Interfaz principal con usuario real
require_once 'config.php';
require_once 'functions.php';

// Obtener usuario actual
$user_id = getCurrentUserId();
if (!$user_id) {
    header('Location: ../login.php');
    exit;
}

// Obtener info del usuario para mostrar
$userInfo = getCurrentUserInfo();
$username = $userInfo['username'] ?? $userInfo['email'] ?? 'Usuario';
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gestor de URLs Cortas</title>
    <link rel="stylesheet" href="assets/css/style.css">
</head>
<body>
    <div class="container">
        <!-- Header -->
        <header class="header">
            <div class="header-left">
                <h1>🚀 Gestor de URLs</h1>
                <div id="stats" class="stats">📊 Cargando estadísticas...</div>
            </div>
            <div class="header-right">
                <span>👤 <?php echo htmlspecialchars($username); ?></span>
                <a href="../logout.php" class="btn-logout">Cerrar sesión</a>
            </div>
        </header>

        <!-- Search -->
        <div class="search-container">
            <input type="text" id="searchInput" placeholder="🔍 Buscar URLs..." class="search-input">
        </div>

        <!-- Action Buttons -->
        <div class="action-buttons">
            <button id="toggleBtn" class="btn btn-primary">➕ Agregar URL</button>
            <button id="syncBtn" class="btn btn-secondary">🔄 Sincronizar</button>
        </div>

        <!-- Add Form -->
        <div id="addForm" class="add-form" style="display: none;">
            <form id="urlForm">
                <div class="form-group">
                    <label for="shortUrl">URL Corta:</label>
                    <input type="url" id="shortUrl" name="shortUrl" placeholder="https://0ln.eu/abc123" class="form-input" required>
                </div>
                <div class="form-group">
                    <label for="title">Título:</label>
                    <input type="text" id="title" name="title" placeholder="Mi enlace importante" class="form-input" required>
                </div>
                <div class="form-group">
                    <label for="category">Categoría:</label>
                    <select id="category" name="category" class="form-input">
                        <option value="">Sin categoría</option>
                        <option value="trabajo">Trabajo</option>
                        <option value="personal">Personal</option>
                        <option value="recursos">Recursos</option>
                        <option value="documentos">Documentos</option>
                        <option value="favoritos">Favoritos</option>
                    </select>
                </div>
                <div class="form-group">
                    <label for="notes">Notas (opcional):</label>
                    <textarea id="notes" name="notes" placeholder="Notas adicionales..." class="form-input" rows="3"></textarea>
                </div>
                <div class="form-actions">
                    <button type="submit" class="btn btn-success">💾 Guardar</button>
                    <button type="button" id="cancelBtn" class="btn btn-secondary">❌ Cancelar</button>
                </div>
            </form>
            <div id="message" class="message" style="display: none;"></div>
        </div>

        <!-- Tools Section -->
        <div class="tools-section">
            <h3>🛠️ Herramientas</h3>
            <div class="tools-grid">
                <button id="importJsonBtn" class="btn btn-secondary">
                    📄 Importar JSON
                </button>
                <button id="exportJsonBtn" class="btn btn-secondary">
                    📤 Exportar JSON
                </button>
                <button id="exportBookmarksBtn" class="btn btn-secondary">
                    🌐 Exportar Favoritos
                </button>
                <button id="clearManagerBtn" class="btn btn-danger">
                    🗑️ Limpiar Gestor
                </button>
            </div>
        </div>

        <!-- Filter Tabs -->
        <div class="filter-tabs">
            <button class="filter-tab active" data-filter="all">Todas</button>
            <button class="filter-tab" data-filter="">Sin categoría</button>
            <button class="filter-tab" data-filter="trabajo">Trabajo</button>
            <button class="filter-tab" data-filter="personal">Personal</button>
            <button class="filter-tab" data-filter="recursos">Recursos</button>
            <button class="filter-tab" data-filter="documentos">Documentos</button>
            <button class="filter-tab" data-filter="favoritos">Favoritos</button>
        </div>

        <!-- URL List -->
        <div class="url-list-container">
            <div id="urlList" class="url-list">
                <div class="loading">
                    <p>⏳ Cargando URLs...</p>
                </div>
            </div>
        </div>

        <!-- Hidden File Input -->
        <input type="file" id="jsonFileInput" accept=".json" style="display: none;">
    </div>

    <script src="assets/js/app.js"></script>
</body>
</html>

// Variables globales
let urls = [];
let draggedElement = null;

// Esperar a que el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
    loadUrls();
    
    // Event listeners principales
    document.getElementById('toggleBtn').addEventListener('click', toggleForm);
    document.getElementById('saveBtn').addEventListener('click', addUrl);
    document.getElementById('searchInput').addEventListener('input', filterUrls);
    
    // Botones de importación/exportación
    document.getElementById('importApiBtn').addEventListener('click', importFromAPI);
    document.getElementById('importFileBtn').addEventListener('click', () => {
        document.getElementById('fileInput').click();
    });
    document.getElementById('fileInput').addEventListener('change', handleFileImport);
    document.getElementById('exportBtn').addEventListener('click', exportUrls);
    document.getElementById('clearBtn').addEventListener('click', clearAllUrls);
    
    // Botones del header
    document.getElementById('openInTab').addEventListener('click', function() {
        chrome.tabs.create({ url: chrome.runtime.getURL('popup.html') });
    });
    
    document.getElementById('openInWindow').addEventListener('click', function() {
        chrome.windows.create({
            url: chrome.runtime.getURL('popup.html'),
            type: 'popup',
            width: 450,
            height: 600
        });
    });
    
    // Enter para guardar
    document.getElementById('shortUrl').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') addUrl();
    });
    document.getElementById('title').addEventListener('keypress', function(e) {
        if (e.key === 'Enter') addUrl();
    });
});

function loadUrls() {
    chrome.storage.local.get(['urls'], function(result) {
        urls = result.urls || [];
        renderUrls();
        updateStats();
    });
}

function updateStats() {
    const totalUrls = urls.length;
    const domains = [...new Set(urls.map(u => extractDomain(u.shortUrl)))];
    document.getElementById('stats').textContent = 
        `📊 ${totalUrls} URLs guardadas | 🌐 ${domains.length} dominios`;
}

function renderUrls(urlsToRender = urls) {
    const list = document.getElementById('urlList');
    
    if (urlsToRender.length === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <div class="empty-state-icon">📭</div>
                <h4>No hay URLs guardadas</h4>
                <p>Agrega tu primera URL corta o importa desde 0ln.eu</p>
            </div>
        `;
        return;
    }
    
    list.innerHTML = urlsToRender.map((url, index) => {
        // Buscar índice real en el array completo
        const realIndex = urls.indexOf(url);
        const favicon = url.favicon || `https://www.google.com/s2/favicons?domain=${extractDomain(url.originalUrl || url.shortUrl)}`;
        const domain = extractDomain(url.shortUrl);
        
        return `
            <div class="url-item" data-index="${realIndex}" draggable="true">
                <div class="url-actions">
                    <button class="btn-action btn-copy" data-index="${realIndex}" title="Copiar URL corta">📋</button>
                    <button class="btn-action btn-delete" data-index="${realIndex}" title="Eliminar">🗑️</button>
                </div>
                
                <div class="url-header">
                    <img src="${favicon}" class="favicon" onerror="this.src='data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAAbwAAAG8B8aLcQwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAGJSURBVDiNpZO/S1VRGMc/5773vuddhKRID7oYRBAUQdHQ0tLQ0H9QQ0tDRGNTEERDQ0NIS1BQUUN/QUOJg4iBUBAU1NCPwaLXe+/7Ps5734aEet97r/2GL5zD93w/53vO+cIJlFJpYBKYBkaALiABBMCu1noHWANWgVUp5W7zWxEAKaVSylFgtlKpXAiCwPE8L66UQmuN1hoA13VDy7J2HMf5bFnWGyHEm9jnMjBZqVTOFQqF1EaxyN7eHkEQ1HeNokT6+/sZHBykUCjcKZfLs4ODgwtRgJlSqXRqu1hku1gk1dJC+K843H9WqZTi186O0pvNniqVShO9vb3PIwDXPM9LbW1v09baSmJmpglOo7jdbMb1PAdwIwKg4Hle3Pf9lvO53Ik4AIh1dKDrBVgFRGgcOl4dP8+tXqDZCQAJtNZYlkWru4/jODiWhWVZiEaNyDhqJKLN+s7/nKfOnwJUa7VaBtBAZiQ5SfW4OFquzqwWBsFRgBCi1tfXt5vP59O1Wu50MyCXy30XQhxE6v4AWq1/NCuOwOkAAAAASUVORK5CYII='">
                    <div class="url-title">${escapeHtml(url.title)}</div>
                </div>
                
                <div class="url-short">
                    🔗 ${escapeHtml(url.shortUrl)}
                    <span class="domain-tag">${escapeHtml(domain)}</span>
                </div>
                
                ${url.originalUrl ? `
                    <div class="url-original" title="${escapeHtml(url.originalUrl)}">
                        ➡️ ${escapeHtml(url.originalUrl)}
                    </div>
                ` : ''}
            </div>
        `;
    }).join('');
    
    // Agregar event listeners después de crear el HTML
    setupUrlEventListeners();
    setupDragAndDrop();
}

// Función para importar desde API
async function importFromAPI() {
    const btn = document.getElementById('importApiBtn');
    btn.disabled = true;
    btn.textContent = '⏳ Importando...';
    
    try {
        // Pedir al usuario su dominio si no es 0ln.eu
        let domain = '0ln.eu';
        const customDomain = prompt('¿Desde qué dominio quieres importar?\n(Deja vacío para 0ln.eu)', '0ln.eu');
        if (customDomain) domain = customDomain.replace(/^https?:\/\//, '').replace(/\/$/, '');
        
        // Intentar obtener URLs del API
        const response = await fetch(`https://${domain}/api/my-urls.php`, {
            credentials: 'include',
            mode: 'cors'
        });
        
        if (!response.ok) {
            throw new Error('No se pudo conectar al servidor');
        }
        
        const apiUrls = await response.json();
        
        if (!Array.isArray(apiUrls)) {
            throw new Error('Formato de respuesta inválido');
        }
        
        // Procesar URLs
        let imported = 0;
        const newUrls = [];
        
        for (const apiUrl of apiUrls) {
            const shortUrl = apiUrl.short_url || `https://${domain}/${apiUrl.short_code}`;
            
            // Verificar si ya existe
            if (!urls.find(u => u.shortUrl === shortUrl)) {
                newUrls.push({
                    shortUrl: shortUrl,
                    title: apiUrl.title || apiUrl.short_code || 'Sin título',
                    originalUrl: apiUrl.original_url || null,
                    favicon: null,
                    date: apiUrl.created_at || new Date().toISOString(),
                    clicks: apiUrl.clicks || 0
                });
                imported++;
            }
        }
        
        if (imported > 0) {
            // Agregar las nuevas URLs
            urls = [...newUrls, ...urls];
            
            // Guardar
            await chrome.storage.local.set({ urls: urls });
            renderUrls();
            updateStats();
            showToast(`✅ ${imported} URLs importadas de ${domain}`);
        } else {
            showToast('ℹ️ No hay URLs nuevas para importar');
        }
        
    } catch (error) {
        console.error('Error:', error);
        showToast('❌ Error al importar. ¿Estás logueado en el sitio?');
    } finally {
        btn.disabled = false;
        btn.textContent = '📥 Importar de 0ln.eu';
    }
}

// Función para importar desde archivo
function handleFileImport(e) {
    const file = e.target.files[0];
    if (!file) return;
    
    const reader = new FileReader();
    reader.onload = async function(e) {
        try {
            const importedData = JSON.parse(e.target.result);
            let urlsToImport = [];
            
            // Detectar formato
            if (Array.isArray(importedData)) {
                urlsToImport = importedData;
            } else if (importedData.urls && Array.isArray(importedData.urls)) {
                urlsToImport = importedData.urls;
            } else {
                throw new Error('Formato de archivo no reconocido');
            }
            
            let imported = 0;
            
            urlsToImport.forEach(url => {
                // Verificar que tenga los campos mínimos
                if (url.shortUrl || (url.short_code && url.domain)) {
                    const shortUrl = url.shortUrl || `https://${url.domain}/${url.short_code}`;
                    
                    if (!urls.find(u => u.shortUrl === shortUrl)) {
                        urls.unshift({
                            shortUrl: shortUrl,
                            title: url.title || url.short_code || 'Importado',
                            originalUrl: url.originalUrl || url.original_url || null,
                            favicon: url.favicon || null,
                            date: url.date || url.created_at || new Date().toISOString()
                        });
                        imported++;
                    }
                }
            });
            
            if (imported > 0) {
                // Guardar
                await chrome.storage.local.set({ urls: urls });
                renderUrls();
                updateStats();
                showToast(`✅ ${imported} URLs importadas del archivo`);
            } else {
                showToast('ℹ️ No hay URLs nuevas en el archivo');
            }
            
        } catch (error) {
            console.error('Error:', error);
            showToast('❌ Error al leer el archivo');
        }
    };
    
    reader.readAsText(file);
    e.target.value = ''; // Limpiar input
}

// Función para exportar URLs
function exportUrls() {
    if (urls.length === 0) {
        showToast('No hay URLs para exportar');
        return;
    }
    
    const exportData = {
        exported_at: new Date().toISOString(),
        total: urls.length,
        urls: urls
    };
    
    const dataStr = JSON.stringify(exportData, null, 2);
    const dataBlob = new Blob([dataStr], {type: 'application/json'});
    
    const link = document.createElement('a');
    link.href = URL.createObjectURL(dataBlob);
    link.download = `urls_backup_${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    
    showToast(`✅ ${urls.length} URLs exportadas`);
}

// Función para limpiar todas las URLs
function clearAllUrls() {
    if (urls.length === 0) {
        showToast('No hay URLs para eliminar');
        return;
    }
    
    if (confirm(`¿Eliminar todas las ${urls.length} URLs?\n\n⚠️ Esta acción no se puede deshacer`)) {
        urls = [];
        chrome.storage.local.set({ urls: urls }, function() {
            renderUrls();
            updateStats();
            showToast('🗑️ Todas las URLs eliminadas');
        });
    }
}

// Resto de funciones (setupUrlEventListeners, setupDragAndDrop, etc.)
function setupUrlEventListeners() {
    // Click en los items para abrir
    document.querySelectorAll('.url-item').forEach(item => {
        item.addEventListener('click', function(e) {
            // No abrir si se hizo click en los botones
            if (e.target.closest('.btn-action')) return;
            
            const index = this.getAttribute('data-index');
            if (urls[index]) {
                chrome.tabs.create({ url: urls[index].shortUrl });
            }
        });
    });
    
    // Botones de copiar
    document.querySelectorAll('.btn-copy').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.stopPropagation();
            const index = parseInt(this.getAttribute('data-index'));
            copyUrl(index);
        });
    });
    
    // Botones de eliminar
    document.querySelectorAll('.btn-delete').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.stopPropagation();
            const index = parseInt(this.getAttribute('data-index'));
            deleteUrl(index);
        });
    });
}

function setupDragAndDrop() {
    const items = document.querySelectorAll('.url-item');
    
    items.forEach((item) => {
        item.addEventListener('dragstart', function(e) {
            draggedElement = parseInt(this.getAttribute('data-index'));
            this.classList.add('dragging');
            e.dataTransfer.effectAllowed = 'move';
        });
        
        item.addEventListener('dragend', function(e) {
            this.classList.remove('dragging');
        });
        
        item.addEventListener('dragover', function(e) {
            if (e.preventDefault) {
                e.preventDefault();
            }
            e.dataTransfer.dropEffect = 'move';
            return false;
        });
        
        item.addEventListener('drop', function(e) {
            if (e.stopPropagation) {
                e.stopPropagation();
            }
            
            const dropIndex = parseInt(this.getAttribute('data-index'));
            
            if (draggedElement !== null && draggedElement !== dropIndex) {
                // Reordenar array
                const draggedItem = urls[draggedElement];
                urls.splice(draggedElement, 1);
                urls.splice(dropIndex, 0, draggedItem);
                
                // Guardar y renderizar
                chrome.storage.local.set({ urls: urls }, function() {
                    renderUrls();
                    showToast('📋 URLs reordenadas');
                });
            }
            
            return false;
        });
    });
}

function toggleForm() {
    const form = document.getElementById('addForm');
    const btn = document.getElementById('toggleBtn');
    
    if (form.style.display === 'none' || form.style.display === '') {
        form.style.display = 'block';
        btn.textContent = '✖️ Cancelar';
        document.getElementById('shortUrl').focus();
    } else {
        form.style.display = 'none';
        btn.textContent = '➕ Agregar URL';
        hideError();
    }
}

async function addUrl() {
    const shortUrlInput = document.getElementById('shortUrl');
    const titleInput = document.getElementById('title');
    const shortUrl = shortUrlInput.value.trim();
    const title = titleInput.value.trim();
    
    if (!shortUrl) {
        showError('Por favor ingresa una URL');
        return;
    }
    
    // Validar que sea una URL válida
    if (!isValidUrl(shortUrl)) {
        showError('Por favor ingresa una URL válida');
        return;
    }
    
    // Verificar si ya existe
    const exists = urls.some(u => u.shortUrl === shortUrl);
    if (exists) {
        showError('Esta URL ya está guardada');
        return;
    }
    
    // Mostrar loading
    showLoading(true);
    hideError();
    
    try {
        // Intentar obtener la URL original
        const urlInfo = await fetchOriginalUrl(shortUrl);
        
        // Crear objeto URL
        const newUrl = {
            shortUrl: shortUrl,
            title: title || urlInfo.title || extractTitle(urlInfo.originalUrl || shortUrl),
            originalUrl: urlInfo.originalUrl || null,
            favicon: urlInfo.favicon || null,
            date: new Date().toISOString()
        };
        
        // Agregar al principio del array
        urls.unshift(newUrl);
        
        // Guardar
        chrome.storage.local.set({ urls: urls }, function() {
            // Limpiar formulario
            shortUrlInput.value = '';
            titleInput.value = '';
            toggleForm();
            renderUrls();
            updateStats();
            showLoading(false);
            showToast('✅ URL guardada');
        });
        
    } catch (error) {
        console.error('Error:', error);
        showError('No se pudo obtener la información de la URL');
        showLoading(false);
    }
}

async function fetchOriginalUrl(shortUrl) {
    try {
        // Extraer el dominio y código de la URL corta
        const url = new URL(shortUrl);
        const domain = url.hostname;
        const code = url.pathname.substring(1);
        
        // No hacer petición si no hay código
        if (!code) return {};
        
        // Intentar diferentes endpoints según el dominio
        let apiUrl = `https://${domain}/api/info.php?code=${code}`;
        
        // Hacer petición con timeout
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), 5000); // 5 segundos timeout
        
        const response = await fetch(apiUrl, {
            signal: controller.signal,
            mode: 'cors'
        });
        
        clearTimeout(timeoutId);
        
        if (response.ok) {
            const data = await response.json();
            return {
                originalUrl: data.original_url || null,
                title: data.title || null,
                favicon: data.favicon || null
            };
        }
    } catch (error) {
        console.log('No se pudo obtener info de API, continuando sin ella');
    }
    
    // Si falla, devolver objeto vacío
    return {};
}

function filterUrls(e) {
    const searchTerm = e.target.value.toLowerCase();
    
    if (!searchTerm) {
        renderUrls();
        return;
    }
    
    const filtered = urls.filter(url => 
        url.title.toLowerCase().includes(searchTerm) ||
        url.shortUrl.toLowerCase().includes(searchTerm) ||
        (url.originalUrl && url.originalUrl.toLowerCase().includes(searchTerm))
    );
    
    renderUrls(filtered);
}

// Funciones auxiliares
function isValidUrl(string) {
    try {
        const url = new URL(string);
        return url.protocol === 'http:' || url.protocol === 'https:';
    } catch (_) {
        return false;
    }
}

function extractDomain(url) {
    try {
        const urlObj = new URL(url);
        return urlObj.hostname;
    } catch (_) {
        return '';
    }
}

function extractTitle(url) {
    try {
        const urlObj = new URL(url);
        return urlObj.hostname.replace('www.', '');
    } catch (_) {
        return url.substring(0, 30) + '...';
    }
}

function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    return text.replace(/[&<>"']/g, m => map[m]);
}

function showLoading(show) {
    document.getElementById('loadingMsg').style.display = show ? 'block' : 'none';
    document.getElementById('saveBtn').disabled = show;
}

function showError(message) {
    const errorMsg = document.getElementById('errorMsg');
    errorMsg.textContent = message;
    errorMsg.style.display = 'block';
}

function hideError() {
    document.getElementById('errorMsg').style.display = 'none';
}

function showToast(message) {
    const existing = document.querySelector('.copy-toast');
    if (existing) existing.remove();
    
    const toast = document.createElement('div');
    toast.className = 'copy-toast';
    toast.textContent = message;
    document.body.appendChild(toast);
    
    setTimeout(() => toast.remove(), 2000);
}

// Funciones para los botones
function copyUrl(index) {
    const url = urls[index];
    if (url) {
        navigator.clipboard.writeText(url.shortUrl).then(() => {
            showToast('✅ URL copiada');
        }).catch(err => {
            // Fallback para cuando falla clipboard API
            const textArea = document.createElement('textarea');
            textArea.value = url.shortUrl;
            document.body.appendChild(textArea);
            textArea.select();
            document.execCommand('copy');
            document.body.removeChild(textArea);
            showToast('✅ URL copiada');
        });
    }
}

// FUNCIÓN CORREGIDA - Elimina tanto local como del servidor
async function deleteUrl(index) {
    const url = urls[index];
    if (!url) return;
    
    const deleteBtn = document.querySelector(`.btn-delete[data-index="${index}"]`);
    const originalContent = deleteBtn.innerHTML;
    
    if (deleteBtn.classList.contains('confirm-delete')) {
        try {
            // Mostrar loading
            deleteBtn.innerHTML = '⏳';
            deleteBtn.disabled = true;
            
            // Extraer código de la URL
            const urlObj = new URL(url.shortUrl);
            const shortCode = urlObj.pathname.substring(1);
            const domain = urlObj.hostname;
            
            // Intentar eliminar del servidor
            try {
                const response = await fetch(`https://${domain}/api/delete-url.php`, {
                    method: 'POST', // POST es más compatible
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    credentials: 'include',
                    body: JSON.stringify({
                        code: shortCode
                    })
                });
                
                if (response.ok) {
                    const result = await response.json();
                    if (!result.success) {
                        console.log('No se pudo eliminar del servidor');
                    }
                }
            } catch (serverError) {
                // Si falla el servidor, continuar con eliminación local
                console.log('Error de servidor, eliminando solo localmente');
            }
            
            // Siempre eliminar localmente (incluso si falla el servidor)
            urls.splice(index, 1);
            await chrome.storage.local.set({ urls: urls });
            renderUrls();
            updateStats();
            showToast('🗑️ URL eliminada');
            
        } catch (error) {
            console.error('Error:', error);
            deleteBtn.innerHTML = originalContent;
            deleteBtn.disabled = false;
            deleteBtn.classList.remove('confirm-delete');
            showToast('❌ Error al eliminar');
        }
    } else {
        // Mostrar confirmación
        deleteBtn.classList.add('confirm-delete');
        deleteBtn.innerHTML = '✓?';
        deleteBtn.title = 'Click para confirmar';
        
        setTimeout(() => {
            if (deleteBtn && !deleteBtn.disabled) {
                deleteBtn.classList.remove('confirm-delete');
                deleteBtn.innerHTML = originalContent;
                deleteBtn.title = 'Eliminar';
            }
        }, 3000);
    }
}
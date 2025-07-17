// assets/js/app.js - Versión de debugging
console.log('🚀 Loading app.js...');

class URLManager {
    constructor() {
        console.log('🔧 URLManager constructor called');
        this.urls = [];
        this.currentFilter = 'all';
        this.searchTerm = '';
        this.init();
    }

    init() {
        console.log('⚡ URLManager init called');
        this.bindEvents();
        this.loadUrls();
        this.updateStats();
    }

    bindEvents() {
        console.log('🔗 Binding events...');
        
        // Test que los elementos existen
        const elements = {
            toggleBtn: document.getElementById('toggleBtn'),
            cancelBtn: document.getElementById('cancelBtn'),
            urlForm: document.getElementById('urlForm'),
            searchInput: document.getElementById('searchInput'),
            syncBtn: document.getElementById('syncBtn'),
            importJsonBtn: document.getElementById('importJsonBtn'),
            exportJsonBtn: document.getElementById('exportJsonBtn'),
            exportBookmarksBtn: document.getElementById('exportBookmarksBtn'),
            clearManagerBtn: document.getElementById('clearManagerBtn'),
            jsonFileInput: document.getElementById('jsonFileInput')
        };
        
        // Verificar elementos
        for (const [name, element] of Object.entries(elements)) {
            if (!element) {
                console.error(`❌ Element ${name} not found!`);
            } else {
                console.log(`✅ Element ${name} found`);
            }
        }
        
        // Bind events con verificación
        if (elements.toggleBtn) {
            elements.toggleBtn.addEventListener('click', () => {
                console.log('🔘 Toggle button clicked');
                this.toggleForm();
            });
        }
        
        if (elements.cancelBtn) {
            elements.cancelBtn.addEventListener('click', () => {
                console.log('❌ Cancel button clicked');
                this.toggleForm();
            });
        }
        
        if (elements.urlForm) {
            elements.urlForm.addEventListener('submit', (e) => {
                console.log('📝 Form submitted');
                this.handleSubmit(e);
            });
        }
        
        if (elements.searchInput) {
            elements.searchInput.addEventListener('input', (e) => {
                console.log('🔍 Search input changed:', e.target.value);
                this.searchTerm = e.target.value.toLowerCase();
                this.renderUrls();
            });
        }
        
        if (elements.syncBtn) {
            elements.syncBtn.addEventListener('click', () => {
                console.log('🔄 Sync button clicked');
                this.syncSystem();
            });
        }
        
        if (elements.importJsonBtn) {
            elements.importJsonBtn.addEventListener('click', () => {
                console.log('📄 Import JSON button clicked');
                this.importJson();
            });
        }
        
        if (elements.exportJsonBtn) {
            elements.exportJsonBtn.addEventListener('click', () => {
                console.log('📤 Export JSON button clicked');
                this.exportJson();
            });
        }
        
        if (elements.exportBookmarksBtn) {
            elements.exportBookmarksBtn.addEventListener('click', () => {
                console.log('🌐 Export bookmarks button clicked');
                this.exportBookmarks();
            });
        }
        
        if (elements.clearManagerBtn) {
            elements.clearManagerBtn.addEventListener('click', () => {
                console.log('🗑️ Clear manager button clicked');
                this.clearManager();
            });
        }
        
        if (elements.jsonFileInput) {
            elements.jsonFileInput.addEventListener('change', (e) => {
                console.log('📁 File input changed');
                this.handleJsonFile(e);
            });
        }
        
        // Filter tabs
        document.querySelectorAll('.filter-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                console.log('🏷️ Filter tab clicked:', e.target.dataset.filter);
                this.setFilter(e.target.dataset.filter);
            });
        });
        
        console.log('✅ All events bound successfully');
    }

    async loadUrls() {
        console.log('📥 Loading URLs...');
        try {
            const response = await fetch('api.php?action=get_urls');
            console.log('🌐 API Response status:', response.status);
            
            if (!response.ok) {
                throw new Error(`HTTP ${response.status}`);
            }
            
            const data = await response.json();
            console.log('📊 API Response data:', data);
            
            if (data.success) {
                this.urls = data.urls || [];
                console.log('✅ URLs loaded:', this.urls.length);
                this.renderUrls();
                this.updateStats();
            } else {
                console.error('❌ API Error:', data.message);
                this.showMessage('Error al cargar URLs: ' + data.message, 'error');
            }
        } catch (error) {
            console.error('❌ Load URLs error:', error);
            this.showMessage('Error de conexión: ' + error.message, 'error');
        }
    }

    renderUrls() {
        console.log('🎨 Rendering URLs...');
        const container = document.getElementById('urlList');
        if (!container) {
            console.error('❌ urlList container not found');
            return;
        }
        
        const filteredUrls = this.getFilteredUrls();
        console.log('🔍 Filtered URLs:', filteredUrls.length);
        
        if (filteredUrls.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <div class="empty-state-icon">📭</div>
                    <h3>No hay URLs</h3>
                    <p>Agrega URLs al gestor o sincroniza con tu sistema</p>
                </div>
            `;
            return;
        }

        container.innerHTML = filteredUrls.map(url => `
            <div class="url-item" data-id="${url.id}">
                <div class="url-actions">
                    <button class="btn-action" onclick="urlManager.copyUrl('${url.short_url}')" title="Copiar">📋</button>
                    <button class="btn-action" onclick="urlManager.openUrl('${url.short_url}')" title="Abrir">🔗</button>
                    ${url.in_manager ? 
                        `<button class="btn-action btn-danger" onclick="urlManager.removeUrl(${url.id})" title="Quitar del gestor">➖</button>` :
                        `<button class="btn-action btn-success" onclick="urlManager.addUrl(${url.id})" title="Agregar al gestor">➕</button>`
                    }
                </div>
                
                <div class="url-header">
                    <img src="${url.favicon || this.getDefaultFavicon(url.original_url)}" 
                         class="favicon" 
                         onerror="this.src='data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHJlY3Qgd2lkdGg9IjE2IiBoZWlnaHQ9IjE2IiByeD0iMiIgZmlsbD0iI2Y4ZjlmYSIvPgo8cGF0aCBkPSJNOCA0YzIuMjA5IDAgNCAxLjc5MSA0IDRzLTEuNzkxIDQtNCA0LTQtMS43OTEtNC00IDEuNzkxLTQgNC00eiIgZmlsbD0iIzZjNzU3ZCIvPgo8L3N2Zz4K'">
                    <div class="url-title">${this.escapeHtml(url.title)}</div>
                    ${url.category ? `<span class="url-category">${this.escapeHtml(url.category)}</span>` : ''}
                    ${url.in_manager ? '<span class="url-category" style="background: #28a745; color: white;">En Gestor</span>' : ''}
                </div>
                
                <div class="url-short">${this.escapeHtml(url.short_url)}</div>
                
                ${url.original_url ? `<div class="url-original">${this.escapeHtml(url.original_url)}</div>` : ''}
                
                ${url.notes ? `<div class="url-notes">📝 ${this.escapeHtml(url.notes)}</div>` : ''}
                
                <div class="url-date">
                    📅 ${this.formatDate(url.created_at)}
                    ${url.clicks !== undefined ? ` | 👆 ${url.clicks} clicks` : ''}
                    ${url.domain ? ` | 🌐 ${url.domain}` : ''}
                </div>
            </div>
        `).join('');
        
        console.log('✅ URLs rendered successfully');
    }

    getFilteredUrls() {
        let filtered = this.urls;
        
        if (this.currentFilter && this.currentFilter !== 'all') {
            filtered = filtered.filter(url => url.category === this.currentFilter);
        }
        
        if (this.searchTerm) {
            filtered = filtered.filter(url => 
                url.title.toLowerCase().includes(this.searchTerm) ||
                url.short_url.toLowerCase().includes(this.searchTerm) ||
                (url.original_url && url.original_url.toLowerCase().includes(this.searchTerm)) ||
                (url.notes && url.notes.toLowerCase().includes(this.searchTerm))
            );
        }
        
        return filtered;
    }

    setFilter(filter) {
        console.log('🏷️ Setting filter:', filter);
        this.currentFilter = filter;
        
        document.querySelectorAll('.filter-tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.filter === filter);
        });
        
        this.renderUrls();
    }

    toggleForm() {
        console.log('📝 Toggling form...');
        const form = document.getElementById('addForm');
        const btn = document.getElementById('toggleBtn');
        
        if (!form || !btn) {
            console.error('❌ Form or button not found');
            return;
        }
        
        if (form.style.display === 'none' || form.style.display === '') {
            form.style.display = 'block';
            btn.textContent = '❌ Cancelar';
            const shortUrlInput = document.getElementById('shortUrl');
            if (shortUrlInput) shortUrlInput.focus();
        } else {
            form.style.display = 'none';
            btn.textContent = '➕ Agregar URL';
            const messageDiv = document.getElementById('message');
            if (messageDiv) messageDiv.style.display = 'none';
        }
    }

    async syncSystem() {
        console.log('🔄 Syncing system...');
        const btn = document.getElementById('syncBtn');
        if (!btn) return;
        
        const originalText = btn.textContent;
        btn.textContent = '⏳ Sincronizando...';
        btn.disabled = true;
        
        try {
            const response = await fetch('api.php?action=sync_system', {
                method: 'POST'
            });
            
            const data = await response.json();
            console.log('🔄 Sync response:', data);
            
            if (data.success) {
                this.showMessage(data.message, 'success');
                this.loadUrls();
            } else {
                this.showMessage(data.message, 'error');
            }
        } catch (error) {
            console.error('❌ Sync error:', error);
            this.showMessage('Error de sincronización: ' + error.message, 'error');
        } finally {
            btn.textContent = originalText;
            btn.disabled = false;
        }
    }

    importJson() {
        console.log('📄 Import JSON...');
        const fileInput = document.getElementById('jsonFileInput');
        if (fileInput) {
            fileInput.click();
        } else {
            console.error('❌ File input not found');
        }
    }

    exportJson() {
        console.log('📤 Export JSON...');
        window.open('api.php?action=export_json', '_blank');
    }

    exportBookmarks() {
        console.log('🌐 Export bookmarks...');
        window.open('api.php?action=export_bookmarks', '_blank');
    }

    async clearManager() {
        console.log('🗑️ Clear manager...');
        if (!confirm('¿Limpiar todas las URLs del gestor?')) return;
        
        try {
            const response = await fetch('api.php?action=clear_manager', {
                method: 'POST'
            });
            
            const data = await response.json();
            console.log('🗑️ Clear response:', data);
            
            if (data.success) {
                this.showMessage(data.message, 'success');
                this.loadUrls();
            } else {
                this.showMessage(data.message, 'error');
            }
        } catch (error) {
            console.error('❌ Clear error:', error);
            this.showMessage('Error: ' + error.message, 'error');
        }
    }

    copyUrl(url) {
        console.log('📋 Copying URL:', url);
        navigator.clipboard.writeText(url).then(() => {
            this.showMessage('URL copiada al portapapeles', 'success');
        }).catch(() => {
            this.showMessage('Error al copiar URL', 'error');
        });
    }

    openUrl(url) {
        console.log('🔗 Opening URL:', url);
        window.open(url, '_blank');
    }

    async updateStats() {
        console.log('📊 Updating stats...');
        try {
            const response = await fetch('api.php?action=get_stats');
            const data = await response.json();
            console.log('📊 Stats response:', data);
            
            if (data.success) {
                const stats = data.stats;
                const statsElement = document.getElementById('stats');
                if (statsElement) {
                    statsElement.textContent = 
                        `📊 ${stats.manager_total} en gestor | 🗄️ ${stats.system_total} en sistema | ⏳ ${stats.sync_pending} pendientes`;
                }
            }
        } catch (error) {
            console.error('❌ Stats error:', error);
        }
    }

    showMessage(message, type = 'info') {
        console.log(`💬 Show message [${type}]:`, message);
        const messageDiv = document.getElementById('message');
        if (!messageDiv) {
            console.error('❌ Message div not found');
            return;
        }
        
        messageDiv.textContent = message;
        messageDiv.className = `message ${type}`;
        messageDiv.style.display = 'block';
        
        setTimeout(() => {
            messageDiv.style.display = 'none';
        }, 5000);
    }

    getDefaultFavicon(url) {
        if (!url) return '';
        try {
            const domain = new URL(url).hostname;
            return `https://www.google.com/s2/favicons?domain=${domain}`;
        } catch {
            return '';
        }
    }

    escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    formatDate(dateString) {
        if (!dateString) return '';
        return new Date(dateString).toLocaleDateString('es-ES', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    }

    // Placeholder methods for actions
    async handleSubmit(e) {
        e.preventDefault();
        console.log('📝 Handle submit');
        // Implementation here
    }

    async handleJsonFile(e) {
        console.log('📁 Handle JSON file');
        // Implementation here
    }

    async removeUrl(id) {
        console.log('➖ Remove URL:', id);
        // Implementation here
    }

    async addUrl(id) {
        console.log('➕ Add URL:', id);
        // Implementation here
    }
}

// Initialize when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    console.log('📄 DOM loaded, initializing URLManager...');
    try {
        window.urlManager = new URLManager();
        console.log('✅ URLManager initialized successfully');
    } catch (error) {
        console.error('❌ Error initializing URLManager:', error);
    }
});

console.log('📦 app.js loaded completely');

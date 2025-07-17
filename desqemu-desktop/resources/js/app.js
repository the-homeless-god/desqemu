/**
 * DESQEMU Desktop Application
 * Main application logic with Neutralino.js integration
 * Updated with noVNC integration
 */

class DesqemuApp {
    constructor() {
        this.qemuProcess = null;
        this.vmStatus = 'stopped';
        this.qemuAvailable = false;
        this.novncProcess = null; // noVNC proxy process
        this.vncFrame = null; // VNC iframe
        
        this.init();
    }

    async init() {
        console.log('🚀 Initializing DESQEMU Desktop...');
        
        // Wait for Neutralino to be ready
        await Neutralino.init();
        
        // Hide loading overlay initially
        this.hideLoadingOverlay();
        
        // Set up event listeners
        this.setupEventListeners();
        
        // Check QEMU availability
        await this.checkQemuStatus();
        
        // Get QCOW2 file size
        await this.updateQcow2Size();
        
        // Start auto-refresh of QEMU processes
        this.startProcessMonitoring();
        
        this.addLog('info', 'DESQEMU Desktop готов к работе');
    }

    setupEventListeners() {
        // Window controls
        document.getElementById('minimizeBtn').addEventListener('click', () => {
            Neutralino.window.minimize();
        });
        
        document.getElementById('closeBtn').addEventListener('click', () => {
            this.handleAppClose();
        });
        
        // QEMU controls
        document.getElementById('refreshQemuBtn').addEventListener('click', () => {
            this.checkQemuStatus();
        });
        
        // Add refresh size button if exists
        const refreshSizeBtn = document.getElementById('refreshSizeBtn');
        if (refreshSizeBtn) {
            refreshSizeBtn.addEventListener('click', () => {
                this.updateQcow2Size();
            });
        }
        
        document.getElementById('installQemuBtn').addEventListener('click', () => {
            this.installQemu();
        });
        
        // VM controls
        document.getElementById('startVmBtn').addEventListener('click', () => {
            this.startMicroVM();
        });
        
        document.getElementById('stopVmBtn').addEventListener('click', () => {
            this.stopMicroVM();
        });
        
        document.getElementById('restartVmBtn').addEventListener('click', () => {
            this.restartMicroVM();
        });
        
        // VNC Display controls
        document.getElementById('toggleDisplayBtn').addEventListener('click', () => {
            this.toggleVNCDisplay();
        });
        
        document.getElementById('hideDisplayBtn').addEventListener('click', () => {
            this.hideVNCDisplay();
        });
        
        document.getElementById('fullscreenBtn').addEventListener('click', () => {
            this.toggleVNCFullscreen();
        });
        
        document.getElementById('retryVncBtn').addEventListener('click', () => {
            this.connectVNC();
        });
        
        // Logs
        document.getElementById('clearLogsBtn').addEventListener('click', () => {
            this.clearLogs();
        });
        
        // Handle app events
        Neutralino.events.on('windowClose', () => {
            this.handleAppClose();
        });
    }

    async checkQemuStatus() {
        this.addLog('info', 'Проверяем доступность QEMU...');
        this.updateQemuStatus('checking', 'Проверяем...');
        
        try {
            // Try to run qemu-system-x86_64 --version
            const result = await Neutralino.os.execCommand('qemu-system-x86_64 --version');
            
            if (result.exitCode === 0) {
                // Parse version
                const versionMatch = result.stdOut.match(/QEMU emulator version ([^\s\n]+)/);
                const version = versionMatch ? versionMatch[1] : 'Unknown';
                
                // Get QEMU path
                const whichResult = await Neutralino.os.execCommand('which qemu-system-x86_64');
                const qemuPath = whichResult.stdOut.trim();
                
                this.qemuAvailable = true;
                this.updateQemuStatus('available', 'Доступен');
                this.showQemuInfo(version, qemuPath);
                this.enableVMControls();
                
                this.addLog('success', `QEMU найден: версия ${version}`);
            } else {
                throw new Error('QEMU not found');
            }
        } catch (error) {
            this.qemuAvailable = false;
            this.updateQemuStatus('missing', 'Не найден');
            this.showInstallButton();
            this.disableVMControls();
            
            this.addLog('warning', 'QEMU не найден. Требуется установка.');
        }
    }

    updateQemuStatus(status, text) {
        const statusElement = document.getElementById('qemuStatus');
        statusElement.className = `status-indicator ${status}`;
        statusElement.innerHTML = status === 'checking' 
            ? '<div class="spinner"></div><span>' + text + '</span>'
            : '<span>' + text + '</span>';
    }

    showQemuInfo(version, path) {
        document.getElementById('qemuVersion').textContent = version;
        document.getElementById('qemuPath').textContent = path;
        document.getElementById('qemuInfo').classList.remove('hidden');
        document.getElementById('qemuActions').classList.remove('hidden');
        document.getElementById('installQemuBtn').classList.add('hidden');
    }

    showInstallButton() {
        document.getElementById('qemuInfo').classList.add('hidden');
        document.getElementById('qemuActions').classList.remove('hidden');
        document.getElementById('installQemuBtn').classList.remove('hidden');
    }

    async installQemu() {
        this.addLog('info', 'Начинаем установку QEMU...');
        
        try {
            const platform = await Neutralino.os.getEnv('OS');
            let installCommand = '';
            
            if (platform.toLowerCase().includes('darwin') || platform.toLowerCase().includes('mac')) {
                // macOS - use Homebrew
                installCommand = 'brew install qemu';
                this.addLog('info', 'Установка через Homebrew: brew install qemu');
            } else if (platform.toLowerCase().includes('linux')) {
                // Linux - try different package managers
                installCommand = 'sudo apt update && sudo apt install -y qemu-system-x86';
                this.addLog('info', 'Установка через APT: sudo apt install qemu-system-x86');
            } else if (platform.toLowerCase().includes('windows')) {
                // Windows - open download page
                await Neutralino.os.open('https://www.qemu.org/download/#windows');
                this.addLog('info', 'Открыта страница загрузки QEMU для Windows');
                return;
            }
            
            if (installCommand) {
                // Show loading overlay
                this.showLoadingOverlay('Устанавливаем QEMU...', 'Это может занять несколько минут');
                
                const result = await Neutralino.os.execCommand(installCommand);
                
                this.hideLoadingOverlay();
                
                if (result.exitCode === 0) {
                    this.addLog('success', 'QEMU успешно установлен!');
                    await this.checkQemuStatus();
                } else {
                    throw new Error(`Installation failed: ${result.stdErr}`);
                }
            }
        } catch (error) {
            this.hideLoadingOverlay();
            this.addLog('error', `Ошибка установки QEMU: ${error.message}`);
            
            // Show manual installation instructions
            await Neutralino.os.showMessageBox(
                'Установка QEMU',
                'Автоматическая установка не удалась. Пожалуйста, установите QEMU вручную:\n\n' +
                'macOS: brew install qemu\n' +
                'Linux: sudo apt install qemu-system-x86\n' +
                'Windows: Скачайте с https://www.qemu.org/download/#windows',
                'OK'
            );
        }
    }

    enableVMControls() {
        document.getElementById('startVmBtn').disabled = false;
    }

    disableVMControls() {
        document.getElementById('startVmBtn').disabled = true;
    }

    async startMicroVM() {
        if (!this.qemuAvailable) {
            this.addLog('error', 'QEMU недоступен');
            return;
        }

        this.addLog('info', 'Запускаем Alpine Linux VM...');
        this.updateVMStatus('starting', 'Запускается...');
        this.showLoadingOverlay('Запуск VM...', 'Инициализация виртуальной машины');

        try {
            // Build QEMU command
            const qemuCommand = this.buildQemuCommand();
            
            // Start QEMU process
            this.qemuProcess = await Neutralino.os.execCommand(qemuCommand);
            
            if (this.qemuProcess.exitCode === 0) {
                this.addLog('success', 'QEMU процесс запущен');
                
                // Wait for VM to boot
                await this.sleep(5000);
                
                // Start noVNC proxy
                await this.startNoVNCProxy();
                
                this.hideLoadingOverlay();
                this.updateVMStatus('running', 'Работает');
                this.showVMControls();
                this.showAccessSection();
                
                this.addLog('success', 'Alpine Linux VM запущена успешно!');
            } else {
                throw new Error(`QEMU failed to start: ${this.qemuProcess.stdErr}`);
            }
        } catch (error) {
            this.hideLoadingOverlay();
            this.updateVMStatus('error', 'Ошибка');
            this.addLog('error', `Ошибка запуска VM: ${error.message}`);
        }
    }

    buildQemuCommand() {
        const qcow2Path = 'resources/qcow2/alpine-bootable.qcow2';
        return `qemu-system-x86_64 -m 1G -smp 2 -vnc :1 -drive file="${qcow2Path}",format=qcow2,if=virtio -daemonize`;
    }

    async startNoVNCProxy() {
        this.addLog('info', 'Запускаем noVNC прокси...');
        
        try {
            // Start noVNC proxy using our script
            const result = await Neutralino.os.execCommand('./start-novnc-proxy.sh');
            
            if (result.exitCode === 0) {
                this.novncProcess = result;
                this.addLog('success', 'noVNC прокси запущен на порту 6901');
            } else {
                throw new Error(`noVNC proxy failed: ${result.stdErr}`);
            }
        } catch (error) {
            this.addLog('error', `Ошибка запуска noVNC прокси: ${error.message}`);
        }
    }

    async stopNoVNCProxy() {
        if (this.novncProcess) {
            try {
                await Neutralino.os.execCommand('pkill -f novnc_proxy');
                this.addLog('info', 'noVNC прокси остановлен');
                this.novncProcess = null;
            } catch (error) {
                this.addLog('warning', 'Ошибка остановки noVNC прокси');
            }
        }
    }

    async stopMicroVM() {
        this.addLog('info', 'Останавливаем Alpine Linux VM...');
        this.updateVMStatus('stopping', 'Останавливается...');

        try {
            // Stop QEMU process
            await Neutralino.os.execCommand('pkill -f "qemu-system-x86_64"');
            
            // Stop noVNC proxy
            await this.stopNoVNCProxy();
            
            this.updateVMStatus('stopped', 'Остановлена');
            this.hideVMControls();
            this.hideAccessSection();
            this.hideVNCDisplay();
            
            this.addLog('success', 'Alpine Linux VM остановлена');
        } catch (error) {
            this.addLog('error', `Ошибка остановки VM: ${error.message}`);
        }
    }

    async restartMicroVM() {
        await this.stopMicroVM();
        await this.sleep(2000);
        await this.startMicroVM();
    }

    updateVMStatus(status, text) {
        this.vmStatus = status;
        const statusElement = document.getElementById('vmStatus');
        const textElement = document.getElementById('vmStatusText');
        
        statusElement.className = `vm-status ${status}`;
        textElement.textContent = text;
    }

    showVMControls() {
        document.getElementById('startVmBtn').classList.add('hidden');
        document.getElementById('stopVmBtn').classList.remove('hidden');
        document.getElementById('restartVmBtn').classList.remove('hidden');
    }

    hideVMControls() {
        document.getElementById('startVmBtn').classList.remove('hidden');
        document.getElementById('stopVmBtn').classList.add('hidden');
        document.getElementById('restartVmBtn').classList.add('hidden');
    }

    showAccessSection() {
        document.getElementById('accessSection').classList.remove('hidden');
    }

    hideAccessSection() {
        document.getElementById('accessSection').classList.add('hidden');
    }

    async isVMRunning() {
        try {
            const result = await Neutralino.os.execCommand('pgrep -f "qemu-system-x86_64"');
            return result.exitCode === 0;
        } catch (error) {
            return false;
        }
    }

    async startProcessMonitoring() {
        // Check VM status every 5 seconds
        setInterval(async () => {
            const isRunning = await this.isVMRunning();
            
            if (isRunning && this.vmStatus === 'stopped') {
                this.updateVMStatus('running', 'Работает');
                this.showVMControls();
                this.showAccessSection();
            } else if (!isRunning && this.vmStatus === 'running') {
                this.updateVMStatus('stopped', 'Остановлена');
                this.hideVMControls();
                this.hideAccessSection();
                this.hideVNCDisplay();
            }
        }, 5000);
    }

    showLoadingOverlay(title = 'Загрузка...', message = 'Подождите...') {
        const overlay = document.getElementById('loadingOverlay');
        if (overlay) {
            overlay.querySelector('h3').textContent = title;
            overlay.querySelector('p').textContent = message;
            overlay.style.display = 'flex';
        }
    }

    hideLoadingOverlay() {
        const overlay = document.getElementById('loadingOverlay');
        if (overlay) {
            overlay.style.display = 'none';
        }
    }

    addLog(type, message) {
        const logsContainer = document.getElementById('logsContainer');
        const timestamp = new Date().toLocaleTimeString();
        
        const logEntry = document.createElement('div');
        logEntry.className = `log-entry ${type}`;
        logEntry.innerHTML = `
            <span class="log-time">${timestamp}</span>
            <span class="log-message">${message}</span>
        `;
        
        logsContainer.appendChild(logEntry);
        logsContainer.scrollTop = logsContainer.scrollHeight;
        
        console.log(`[${type.toUpperCase()}] ${message}`);
    }

    clearLogs() {
        document.getElementById('logsContainer').innerHTML = '';
    }

    toggleVNCDisplay() {
        const displaySection = document.getElementById('displaySection');
        
        if (displaySection.classList.contains('hidden')) {
            this.showVNCDisplay();
        } else {
            this.hideVNCDisplay();
        }
    }

    showVNCDisplay() {
        const displaySection = document.getElementById('displaySection');
        displaySection.classList.remove('hidden');
        this.connectVNC();
    }

    hideVNCDisplay() {
        const displaySection = document.getElementById('displaySection');
        displaySection.classList.add('hidden');
        
        // Remove VNC iframe if exists
        if (this.vncFrame) {
            this.vncFrame.remove();
            this.vncFrame = null;
        }
    }

    toggleVNCFullscreen() {
        const vncContainer = document.getElementById('vncContainer');
        if (vncContainer.requestFullscreen) {
            vncContainer.requestFullscreen();
        }
    }

    async connectVNC() {
        this.addLog('info', 'Подключаемся к VNC через noVNC...');
        this.showVNCStatus('Подключение к VNC...');
        
        try {
            // Create iframe for noVNC
            const vncContainer = document.getElementById('vncContainer');
            
            // Remove existing iframe
            if (this.vncFrame) {
                this.vncFrame.remove();
            }
            
            // Create new iframe
            this.vncFrame = document.createElement('iframe');
            this.vncFrame.src = 'http://localhost:6901/vnc.html?host=localhost&port=6901';
            this.vncFrame.style.width = '100%';
            this.vncFrame.style.height = '100%';
            this.vncFrame.style.border = 'none';
            this.vncFrame.style.minHeight = '500px';
            this.vncFrame.allowFullscreen = true;
            
            vncContainer.appendChild(this.vncFrame);
            
            // Show display section
            document.getElementById('displaySection').classList.remove('hidden');
            this.hideVNCStatus();
            this.hideVNCError();
            
            this.updateVNCStatus('Подключен');
            this.addLog('success', 'VNC подключен через noVNC');
            
        } catch (error) {
            this.showVNCError('Не удалось подключиться к VNC');
            this.addLog('error', `Ошибка подключения VNC: ${error.message}`);
        }
    }

    showVNCStatus(message) {
        const statusElement = document.getElementById('vncStatus');
        statusElement.innerHTML = '<div class="spinner"></div><span>' + message + '</span>';
        statusElement.classList.remove('hidden');
    }

    hideVNCStatus() {
        document.getElementById('vncStatus').classList.add('hidden');
    }

    showVNCError(message) {
        const errorElement = document.getElementById('vncError');
        errorElement.querySelector('h4').textContent = message;
        errorElement.classList.remove('hidden');
    }

    hideVNCError() {
        document.getElementById('vncError').classList.add('hidden');
    }

    updateVNCStatus(status) {
        document.getElementById('vncStatusText').textContent = status;
    }

    async handleAppClose() {
        this.addLog('info', 'Закрытие приложения...');
        
        // Stop VM if running
        if (this.vmStatus === 'running') {
            await this.stopMicroVM();
        }
        
        // Stop noVNC proxy
        await this.stopNoVNCProxy();
        
        // Close app
        Neutralino.app.exit();
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }

    async updateQcow2Size() {
        try {
            const qcow2Path = 'resources/qcow2/alpine-bootable.qcow2';
            
            // Get file size using ls command
            const result = await Neutralino.os.execCommand(`ls -lh "${qcow2Path}" | awk '{print $5}'`);
            
            if (result.exitCode === 0) {
                const size = result.stdOut.trim();
                document.getElementById('qcow2Size').textContent = size;
                this.addLog('info', `Размер QCOW2 файла: ${size}`);
                
                // Also get QCOW2 info using qemu-img (only if VM is not running)
                try {
                    const qemuImgResult = await Neutralino.os.execCommand(`qemu-img info "${qcow2Path}" 2>/dev/null`);
                    if (qemuImgResult.exitCode === 0) {
                        // Extract virtual size and disk size
                        const virtualSizeMatch = qemuImgResult.stdOut.match(/virtual size: (\d+ \w+)/);
                        const diskSizeMatch = qemuImgResult.stdOut.match(/disk size: (\d+ \w+)/);
                        
                        if (virtualSizeMatch && diskSizeMatch) {
                            const virtualSize = virtualSizeMatch[1];
                            const diskSize = diskSizeMatch[1];
                            this.addLog('info', `Виртуальный размер: ${virtualSize}, Размер на диске: ${diskSize}`);
                        }
                    }
                } catch (qemuError) {
                    // Ignore qemu-img errors, size is already displayed
                }
            } else {
                // Fallback: try to get size in bytes and convert
                const bytesResult = await Neutralino.os.execCommand(`ls -l "${qcow2Path}" | awk '{print $5}'`);
                if (bytesResult.exitCode === 0) {
                    const bytes = parseInt(bytesResult.stdOut.trim());
                    const size = this.formatBytes(bytes);
                    document.getElementById('qcow2Size').textContent = size;
                    this.addLog('info', `Размер QCOW2 файла: ${size}`);
                } else {
                    document.getElementById('qcow2Size').textContent = 'Не найден';
                    this.addLog('warning', 'QCOW2 файл не найден');
                }
            }
        } catch (error) {
            document.getElementById('qcow2Size').textContent = 'Ошибка';
            this.addLog('error', `Ошибка получения размера файла: ${error.message}`);
        }
    }

    formatBytes(bytes) {
        if (bytes === 0) return '0 B';
        
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }
}

// Initialize app when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new DesqemuApp();
});

// Handle global errors
window.addEventListener('error', (event) => {
    console.error('Application error:', event.error);
});

// Expose app for debugging
window.DesqemuApp = DesqemuApp; 

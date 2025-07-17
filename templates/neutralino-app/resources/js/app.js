/**
 * DESQEMU Desktop Application
 * Main application logic with Neutralino.js integration
 */

class DesqemuApp {
    constructor() {
        this.qemuProcess = null;
        this.vmStatus = 'stopped';
        this.qemuAvailable = false;
        this.rfb = null; // VNC connection
        
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
                'Windows: скачайте с https://www.qemu.org/download/'
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
            this.addLog('error', 'QEMU не найден. Установите QEMU для запуска VM.');
            return;
        }

        this.addLog('info', 'Запускаем Penpot MicroVM...');
        this.showLoadingOverlay('Запускаем Penpot...', 'Подождите, VM загружается...');
        
        try {
            // Update VM status
            this.updateVMStatus('starting', 'Запускается...');
            
            // Start WebSockify proxy for VNC
            await this.startWebsockifyProxy();
            
            // Build QEMU command
            const qemuCommand = this.buildQemuCommand();
            this.addLog('info', `Выполняем: ${qemuCommand}`);
            
            // Start QEMU process in background
            this.qemuProcess = await Neutralino.os.spawnProcess(qemuCommand);
            
            // Wait a bit for VM to start
            await this.sleep(3000);
            
            // Check if process is still running
            if (await this.isVMRunning()) {
                this.updateVMStatus('running', 'Запущена');
                this.showVMControls();
                this.showAccessSection();
                this.addLog('success', 'Penpot MicroVM успешно запущена!');
                this.addLog('info', 'Доступ: http://localhost:8080');
                
                // Auto-open browser after a delay
                setTimeout(() => {
                    Neutralino.os.open('http://localhost:8080');
                }, 2000);
            } else {
                throw new Error('VM failed to start');
            }
            
        } catch (error) {
            this.updateVMStatus('stopped', 'Ошибка запуска');
            this.addLog('error', `Ошибка запуска VM: ${error.message}`);
        } finally {
            this.hideLoadingOverlay();
        }
    }

    buildQemuCommand() {
        // For demo purposes, we'll use a simple command
        // In real implementation, this would point to actual QCOW2 file
        const qcowPath = 'resources/qcow2/penpot-microvm.qcow2';
        
        return `qemu-system-x86_64 \\
            -m 1G \\
            -smp 2 \\
            -netdev user,id=net0,hostfwd=tcp::8080-:8080,hostfwd=tcp::5900-:5900,hostfwd=tcp::6900-:6900,hostfwd=tcp::2222-:22 \\
            -device e1000,netdev=net0 \\
            -vnc :0,password \\
            -monitor stdio \\
            -daemonize \\
            -pidfile /tmp/desqemu-penpot.pid \\
            -drive file=${qcowPath},format=qcow2,if=virtio`;
    }
    
    async startWebsockifyProxy() {
        // Start websockify proxy for noVNC (VNC WebSocket proxy)
        try {
            const websockifyCmd = 'websockify --web=/dev/null 6900 localhost:5900';
            await Neutralino.os.spawnProcess(websockifyCmd);
            this.addLog('info', 'WebSockify прокси запущен на порту 6900');
            return true;
        } catch (error) {
            this.addLog('warning', 'Не удалось запустить websockify прокси');
            this.addLog('info', 'Используется прямое VNC подключение');
            return false;
        }
    }
    
    async stopWebsockifyProxy() {
        try {
            await Neutralino.os.execCommand('pkill -f "websockify.*6900"');
            this.addLog('info', 'WebSockify прокси остановлен');
        } catch (error) {
            // Ignore errors when stopping websockify
        }
    }

    async stopMicroVM() {
        this.addLog('info', 'Останавливаем Penpot MicroVM...');
        
        try {
            if (this.qemuProcess) {
                // Try to kill the process gracefully
                await Neutralino.os.execCommand(`kill ${this.qemuProcess.pid}`);
            }
            
            // Also try to kill by PID file
            try {
                await Neutralino.os.execCommand('pkill -f "qemu-system-x86_64.*penpot"');
            } catch (e) {
                // Ignore if no process found
            }
            
            // Stop WebSockify proxy
            await this.stopWebsockifyProxy();
            
            this.updateVMStatus('stopped', 'Остановлена');
            this.hideVMControls();
            this.hideAccessSection();
            this.qemuProcess = null;
            
            this.addLog('success', 'Penpot MicroVM остановлена');
            
        } catch (error) {
            this.addLog('error', `Ошибка остановки VM: ${error.message}`);
        }
    }

    async restartMicroVM() {
        this.addLog('info', 'Перезапускаем Penpot MicroVM...');
        await this.stopMicroVM();
        await this.sleep(1000);
        await this.startMicroVM();
    }

    updateVMStatus(status, text) {
        const statusElement = document.getElementById('vmStatus');
        statusElement.className = `vm-status ${status}`;
        document.getElementById('vmStatusText').textContent = text;
        this.vmStatus = status;
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
            const result = await Neutralino.os.execCommand('pgrep -f "qemu-system-x86_64.*penpot"');
            return result.exitCode === 0;
        } catch (error) {
            return false;
        }
    }

    async startProcessMonitoring() {
        // Check VM status every 5 seconds
        setInterval(async () => {
            if (this.vmStatus === 'running') {
                const isRunning = await this.isVMRunning();
                if (!isRunning) {
                    this.updateVMStatus('stopped', 'Остановлена');
                    this.hideVMControls();
                    this.hideAccessSection();
                    this.addLog('warning', 'Penpot MicroVM неожиданно остановлена');
                }
            }
        }, 5000);
    }

    showLoadingOverlay(title = 'Загрузка...', message = 'Подождите...') {
        const overlay = document.getElementById('loadingOverlay');
        overlay.querySelector('h3').textContent = title;
        overlay.querySelector('p').textContent = message;
        overlay.style.display = 'flex';
    }

    hideLoadingOverlay() {
        document.getElementById('loadingOverlay').style.display = 'none';
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
        const logsContainer = document.getElementById('logsContainer');
        logsContainer.innerHTML = '';
        this.addLog('info', 'Логи очищены');
    }

    // VNC Display Management
    toggleVNCDisplay() {
        const displaySection = document.getElementById('displaySection');
        const toggleBtn = document.getElementById('toggleDisplayBtn');
        const btnText = toggleBtn.querySelector('.btn-text');
        
        if (displaySection.classList.contains('hidden')) {
            displaySection.classList.remove('hidden');
            btnText.textContent = 'Скрыть дисплей VM';
            this.connectVNC();
            this.addLog('info', 'Отображение VNC дисплея');
        } else {
            this.hideVNCDisplay();
        }
    }
    
    hideVNCDisplay() {
        const displaySection = document.getElementById('displaySection');
        const toggleBtn = document.getElementById('toggleDisplayBtn');
        const btnText = toggleBtn.querySelector('.btn-text');
        
        displaySection.classList.add('hidden');
        btnText.textContent = 'Показать дисплей VM';
        this.disconnectVNC();
        this.addLog('info', 'VNC дисплей скрыт');
    }
    
    toggleVNCFullscreen() {
        const vncContainer = document.getElementById('vncContainer');
        
        if (vncContainer.classList.contains('vnc-fullscreen')) {
            vncContainer.classList.remove('vnc-fullscreen');
            this.addLog('info', 'Выход из полноэкранного режима VNC');
        } else {
            vncContainer.classList.add('vnc-fullscreen');
            this.addLog('info', 'VNC в полноэкранном режиме');
        }
    }
    
    async connectVNC() {
        if (this.vmStatus !== 'running') {
            this.showVNCError('Виртуальная машина не запущена');
            return;
        }
        
        this.addLog('info', 'Подключение к VNC серверу...');
        this.showVNCStatus('Подключение к VNC...');
        
        try {
            // Initialize VNC connection
            const canvas = document.getElementById('vncCanvas');
            const host = 'localhost';
            const port = 5900;
            const password = 'desqemu';
            
            // Create WebSocket URL for VNC WebSocket proxy
            const wsUrl = `ws://${host}:6900`; // WebSockify proxy port
            
            this.addLog('info', `VNC URL: ${wsUrl}`);
            
            // Create RFB connection
            this.rfb = new RFB(canvas, wsUrl, {
                credentials: { password: password }
            });
            
            // Set up event handlers
            this.rfb.addEventListener('connect', () => {
                this.onVNCConnect();
            });
            
            this.rfb.addEventListener('disconnect', (e) => {
                this.onVNCDisconnect(e);
            });
            
            this.rfb.addEventListener('securityfailure', (e) => {
                this.showVNCError('Ошибка авторизации VNC');
                this.addLog('error', `VNC security failure: ${e.detail?.status || 'unknown'}`);
            });
            
        } catch (error) {
            this.showVNCError('Ошибка подключения к VNC');
            this.addLog('error', `VNC connection error: ${error.message}`);
        }
    }
    
    disconnectVNC() {
        if (this.rfb) {
            this.rfb.disconnect();
            this.rfb = null;
        }
        this.updateVNCStatus('Отключен');
        this.hideVNCStatus();
    }
    
    onVNCConnect() {
        this.hideVNCStatus();
        this.hideVNCError();
        this.updateVNCStatus('Подключен');
        
        // Get screen resolution
        if (this.rfb && this.rfb._fb_width && this.rfb._fb_height) {
            const resolution = `${this.rfb._fb_width}x${this.rfb._fb_height}`;
            document.getElementById('vncResolution').textContent = resolution;
        }
        
        this.addLog('success', 'VNC подключение установлено');
    }
    
    onVNCDisconnect(event) {
        this.updateVNCStatus('Отключен');
        document.getElementById('vncResolution').textContent = '-';
        
        if (event.detail.clean) {
            this.addLog('info', 'VNC отключен');
        } else {
            this.showVNCError('Соединение с VNC потеряно');
            this.addLog('warning', 'VNC соединение потеряно');
        }
    }
    
    showVNCStatus(message) {
        const status = document.getElementById('vncStatus');
        const container = document.getElementById('vncContainer');
        const error = document.getElementById('vncError');
        
        status.querySelector('span').textContent = message;
        status.classList.remove('hidden');
        container.classList.add('hidden');
        error.classList.add('hidden');
    }
    
    hideVNCStatus() {
        const status = document.getElementById('vncStatus');
        const container = document.getElementById('vncContainer');
        
        status.classList.add('hidden');
        container.classList.remove('hidden');
    }
    
    showVNCError(message) {
        const error = document.getElementById('vncError');
        const status = document.getElementById('vncStatus');
        const container = document.getElementById('vncContainer');
        
        error.querySelector('p').textContent = message;
        error.classList.remove('hidden');
        status.classList.add('hidden');
        container.classList.add('hidden');
    }
    
    hideVNCError() {
        const error = document.getElementById('vncError');
        error.classList.add('hidden');
    }
    
    updateVNCStatus(status) {
        document.getElementById('vncStatusText').textContent = status;
    }

    async handleAppClose() {
        // Disconnect VNC before closing
        this.disconnectVNC();
        
        if (this.vmStatus === 'running') {
            const shouldStop = await Neutralino.os.showMessageBox(
                'Закрытие приложения',
                'Penpot MicroVM еще запущена. Остановить перед закрытием?',
                'YES_NO'
            );
            
            if (shouldStop === 'YES') {
                await this.stopMicroVM();
            }
        }
        
        Neutralino.app.exit();
    }

    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
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

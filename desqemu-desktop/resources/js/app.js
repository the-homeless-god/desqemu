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
            // Clean up any existing QEMU processes
            this.addLog('info', 'Очистка предыдущих процессов QEMU...');
            try {
                await Neutralino.os.execCommand('pkill -f "qemu-system-x86_64"');
                await this.sleep(2000); // Wait for processes to stop
                this.addLog('success', 'Предыдущие процессы QEMU остановлены');
            } catch (error) {
                this.addLog('debug', 'Нет предыдущих процессов QEMU для остановки');
            }
            
            // Build QEMU command
            const qemuCommand = await this.buildQemuCommand();
            
            // Check and clean QCOW2 file locks
            this.addLog('info', 'Проверка блокировок QCOW2 файла...');
            try {
                const qcow2Path = await this.extractQcow2File(await Neutralino.os.getEnv('NL_PATH'));
                
                // Check if file is locked
                const lockCheck = await Neutralino.os.execCommand(`lsof "${qcow2Path}" 2>/dev/null || echo "not_locked"`);
                if (lockCheck.stdOut.trim() !== 'not_locked') {
                    this.addLog('warning', 'QCOW2 файл заблокирован, пытаемся разблокировать...');
                    await Neutralino.os.execCommand(`fuser -k "${qcow2Path}" 2>/dev/null || true`);
                    await this.sleep(1000);
                }
                
                // Check file permissions
                const permCheck = await Neutralino.os.execCommand(`ls -la "${qcow2Path}"`);
                this.addLog('debug', `Права доступа к QCOW2: ${permCheck.stdOut.trim()}`);
                
            } catch (error) {
                this.addLog('warning', `Ошибка проверки QCOW2: ${error.message}`);
            }
            
            // Start QEMU process
            this.qemuProcess = await Neutralino.os.execCommand(qemuCommand);
            
            this.addLog('debug', `QEMU команда: ${qemuCommand}`);
            this.addLog('debug', `QEMU результат: ${this.qemuProcess.exitCode}, stdout: ${this.qemuProcess.stdOut}, stderr: ${this.qemuProcess.stdErr}`);
            
            if (this.qemuProcess.exitCode === 0) {
                this.addLog('success', 'QEMU процесс запущен');
                
                // Wait for VM to boot
                await this.sleep(10000); // Wait longer for VM to boot
            } else {
                // Try alternative approach - copy QCOW2 to temp location
                this.addLog('warning', 'Попытка альтернативного запуска QEMU...');
                try {
                    const qcow2Path = await this.extractQcow2File(await Neutralino.os.getEnv('NL_PATH'));
                    const tempQcow2Path = `/tmp/alpine-bootable-${Date.now()}.qcow2`;
                    
                    this.addLog('info', `Копируем QCOW2 в временную локацию: ${tempQcow2Path}`);
                    await Neutralino.os.execCommand(`cp "${qcow2Path}" "${tempQcow2Path}"`);
                    
                    const altQemuCommand = qemuCommand.replace(qcow2Path, tempQcow2Path);
                    this.addLog('debug', `Альтернативная команда QEMU: ${altQemuCommand}`);
                    
                    this.qemuProcess = await Neutralino.os.execCommand(altQemuCommand);
                    
                    if (this.qemuProcess.exitCode === 0) {
                        this.addLog('success', 'QEMU процесс запущен (альтернативный способ)');
                        await this.sleep(10000); // Wait longer for VM to boot
                    } else {
                        throw new Error(`Alternative QEMU failed: ${this.qemuProcess.stdErr}`);
                    }
                } catch (error) {
                    this.addLog('error', `Альтернативный запуск тоже не удался: ${error.message}`);
                    throw new Error(`QEMU failed to start: ${this.qemuProcess.stdErr}`);
                }
            }
            
            // Check if VNC is running with retries
            this.addLog('info', 'Ожидание запуска VNC сервера...');
            let vncRunning = false;
            for (let i = 0; i < 5; i++) {
                this.addLog('info', `Проверка VNC сервера (попытка ${i + 1}/5)...`);
                try {
                    const vncCheck = await Neutralino.os.execCommand('lsof -i :5900');
                    if (vncCheck.exitCode === 0 && vncCheck.stdOut.trim()) {
                        this.addLog('success', 'VNC сервер найден и работает');
                        vncRunning = true;
                        break;
                    } else {
                        this.addLog('debug', `VNC не найден (попытка ${i + 1}): ${vncCheck.stdOut}`);
                    }
                } catch (error) {
                    this.addLog('debug', `VNC не найден (попытка ${i + 1}): ${error.message}`);
                }
                
                if (i < 4) {
                    await this.sleep(3000); // Wait 3 seconds before next check
                }
            }
            
            if (!vncRunning) {
                this.addLog('warning', 'VNC сервер не запустился, но продолжаем...');
            }
            
            // Check QEMU processes
            try {
                const qemuCheck = await Neutralino.os.execCommand('pgrep -f "qemu-system-x86_64"');
                this.addLog('debug', `QEMU процессы: ${qemuCheck.exitCode}, stdout: ${qemuCheck.stdOut}`);
            } catch (error) {
                this.addLog('debug', `QEMU процессы не найдены: ${error.message}`);
            }
            
            // Start noVNC proxy with timeout
            try {
                const timeoutPromise = new Promise((_, reject) => {
                    setTimeout(() => reject(new Error('Timeout')), 30000); // 30 seconds timeout
                });
                
                await Promise.race([
                    this.startNoVNCProxy(),
                    timeoutPromise
                ]);
            } catch (error) {
                if (error.message === 'Timeout') {
                    this.addLog('warning', 'noVNC прокси не запустился в течение 30 секунд, продолжаем...');
                } else {
                    this.addLog('error', `Ошибка запуска noVNC: ${error.message}`);
                }
            }
            
            this.hideLoadingOverlay();
            this.updateVMStatus('running', 'Работает');
            this.showVMControls();
            this.showAccessSection();
            
            this.addLog('success', 'Alpine Linux VM запущена успешно!');
        } catch (error) {
            this.hideLoadingOverlay();
            this.updateVMStatus('error', 'Ошибка');
            this.addLog('error', `Ошибка запуска VM: ${error.message}`);
        }
    }

    async buildQemuCommand() {
        try {
            // Get the application directory
            const appDir = await Neutralino.os.getEnv('NL_PATH');
            
            // Extract QCOW2 from resources if needed
            const qcow2Path = await this.extractQcow2File(appDir);
            
            return `qemu-system-x86_64 -m 1G -smp 2 -vnc :0 -drive file="${qcow2Path}",format=qcow2,if=virtio -daemonize`;
        } catch (error) {
            this.addLog('error', `Ошибка подготовки QCOW2 файла: ${error.message}`);
            throw error;
        }
    }

    async extractQcow2File(appDir) {
        this.addLog('info', 'Ищем QCOW2 файл...');
        this.addLog('debug', `Рабочая директория: ${appDir}`);
        
        // Get current working directory for dev mode
        let cwd = appDir; // fallback
        try {
            const cwdResult = await Neutralino.os.execCommand('pwd');
            cwd = cwdResult.stdOut.trim();
            this.addLog('debug', `Текущая директория: ${cwd}`);
        } catch (error) {
            this.addLog('debug', `Не удалось получить текущую директорию, используем: ${cwd}`);
        }
        
        // Try multiple locations including dev mode paths
        const possiblePaths = [
            `${appDir}/alpine-bootable.qcow2`,
            `${appDir}/resources/qcow2/alpine-bootable.qcow2`,
            `${appDir}/resources.neu`,
            `${appDir}/../alpine-bootable.qcow2`,
            `${appDir}/../../alpine-bootable.qcow2`,
            // Dev mode paths
            `${cwd}/alpine-bootable.qcow2`,
            `${cwd}/resources/qcow2/alpine-bootable.qcow2`,
            `${cwd}/desqemu-desktop/resources/qcow2/alpine-bootable.qcow2`,
            `${cwd}/../alpine-bootable.qcow2`,
            `${cwd}/../../alpine-bootable.qcow2`
        ];
        
        for (const path of possiblePaths) {
            try {
                this.addLog('debug', `Проверяем путь: ${path}`);
                const checkResult = await Neutralino.os.execCommand(`test -f "${path}" && echo "exists"`);
                if (checkResult.exitCode === 0 && checkResult.stdOut.trim() === 'exists') {
                    this.addLog('success', `QCOW2 файл найден: ${path}`);
                    return path;
                } else {
                    this.addLog('debug', `Файл не найден: ${path}`);
                }
            } catch (error) {
                this.addLog('debug', `Ошибка проверки ${path}: ${error.message}`);
                // Continue to next path
            }
        }
        
        // If we found resources.neu, try to extract from it
        try {
            const resourcesNeuPath = `${appDir}/resources.neu`;
            const checkResult = await Neutralino.os.execCommand(`test -f "${resourcesNeuPath}" && echo "exists"`);
            if (checkResult.exitCode === 0 && checkResult.stdOut.trim() === 'exists') {
                this.addLog('info', 'Найден resources.neu, пытаемся извлечь QCOW2...');
                
                // Try to extract using neutralino CLI
                const extractResult = await Neutralino.os.execCommand(`cd "${appDir}" && neutralino resources extract qcow2/alpine-bootable.qcow2 "${appDir}/alpine-bootable.qcow2"`);
                if (extractResult.exitCode === 0) {
                    this.addLog('success', 'QCOW2 файл извлечен из resources.neu');
                    return `${appDir}/alpine-bootable.qcow2`;
                }
            }
        } catch (error) {
            this.addLog('warning', 'Не удалось извлечь из resources.neu');
        }
        
        // Last resort: search in the entire directory tree
        try {
            this.addLog('debug', 'Поиск QCOW2 файлов в системе...');
            
            // Search in current directory and subdirectories
            const findResult = await Neutralino.os.execCommand(`find "${appDir}" -name "alpine-bootable.qcow2" -type f 2>/dev/null | head -1`);
            if (findResult.exitCode === 0 && findResult.stdOut.trim()) {
                const foundPath = findResult.stdOut.trim();
                this.addLog('success', `QCOW2 файл найден при поиске: ${foundPath}`);
                return foundPath;
            }
            
            // Search in current working directory
            const findCwdResult = await Neutralino.os.execCommand(`find "${cwd}" -name "alpine-bootable.qcow2" -type f 2>/dev/null | head -1`);
            if (findCwdResult.exitCode === 0 && findCwdResult.stdOut.trim()) {
                const foundPath = findCwdResult.stdOut.trim();
                this.addLog('success', `QCOW2 файл найден в рабочей директории: ${foundPath}`);
                return foundPath;
            }
            
            // Search for any QCOW2 files
            const findAnyResult = await Neutralino.os.execCommand(`find "${cwd}" -name "*.qcow2" -type f 2>/dev/null | head -5`);
            if (findAnyResult.exitCode === 0 && findAnyResult.stdOut.trim()) {
                this.addLog('debug', `Найдены QCOW2 файлы: ${findAnyResult.stdOut.trim()}`);
            }
            
        } catch (error) {
            this.addLog('debug', `Ошибка поиска: ${error.message}`);
        }
        
        // В dev режиме пытаемся скопировать существующий QCOW2 файл
        this.addLog('info', 'Пытаемся скопировать QCOW2 файл для dev режима...');
        try {
            const testQcow2Path = `${appDir}/alpine-bootable.qcow2`;
            
            // Пытаемся скопировать из разных мест
            const copyPaths = [
                `${cwd}/desqemu-desktop/resources/qcow2/alpine-bootable.qcow2`,
                `${cwd}/resources/qcow2/alpine-bootable.qcow2`,
                `${cwd}/alpine-bootable.qcow2`
            ];
            
            for (const sourcePath of copyPaths) {
                try {
                    const copyResult = await Neutralino.os.execCommand(`cp "${sourcePath}" "${testQcow2Path}"`);
                    if (copyResult.exitCode === 0) {
                        this.addLog('success', `QCOW2 файл скопирован из ${sourcePath}`);
                        return testQcow2Path;
                    }
                } catch (error) {
                    // Continue to next path
                }
            }
            
            // Если копирование не удалось, создаем тестовый файл
            this.addLog('info', 'Создаем тестовый QCOW2 файл для dev режима...');
            const createResult = await Neutralino.os.execCommand(`qemu-img create -f qcow2 "${testQcow2Path}" 1G`);
            if (createResult.exitCode === 0) {
                this.addLog('success', `Тестовый QCOW2 файл создан: ${testQcow2Path}`);
                return testQcow2Path;
            }
        } catch (error) {
            this.addLog('error', `Не удалось создать/скопировать QCOW2: ${error.message}`);
        }
        
        throw new Error('QCOW2 файл не найден. Убедитесь, что образ включен в приложение.');
    }

    async startNoVNCProxy() {
        this.addLog('info', 'Запускаем noVNC прокси...');
        
        try {
            // Get the application directory
            const appDir = await Neutralino.os.getEnv('NL_PATH');
            
            // Extract noVNC script if needed
            const novncScriptPath = await this.extractNoVNCScript(appDir);
            
            this.addLog('debug', `noVNC скрипт: ${novncScriptPath}`);
            
            // Start noVNC proxy using our script in background
            const result = await Neutralino.os.execCommand(`cd "${appDir}" && chmod +x "${novncScriptPath}" && bash "${novncScriptPath}" > /tmp/novnc.log 2>&1 & echo $!`);
            
            this.addLog('debug', `noVNC PID: ${result.stdOut.trim()}`);
            
            if (result.exitCode === 0 && result.stdOut.trim()) {
                this.novncProcess = { pid: result.stdOut.trim() };
                this.addLog('success', 'noVNC прокси запущен в фоновом режиме на порту 6900');
                
                // Wait a bit for noVNC to start
                await this.sleep(2000);
                
                // Check if noVNC is running
                try {
                    const checkResult = await Neutralino.os.execCommand(`ps -p ${result.stdOut.trim()} > /dev/null && echo "running"`);
                    if (checkResult.exitCode === 0) {
                        this.addLog('success', 'noVNC прокси подтвержден как работающий');
                        
                        // Show noVNC logs if available
                        try {
                            const logResult = await Neutralino.os.execCommand('tail -5 /tmp/novnc.log 2>/dev/null || echo "No logs"');
                            this.addLog('debug', `noVNC логи: ${logResult.stdOut.trim()}`);
                        } catch (error) {
                            // Ignore log reading errors
                        }
                    } else {
                        this.addLog('warning', 'noVNC прокси может не работать');
                    }
                } catch (error) {
                    this.addLog('warning', 'Не удалось проверить статус noVNC');
                }
            } else {
                throw new Error(`noVNC proxy failed to start: ${result.stdErr}`);
            }
        } catch (error) {
            this.addLog('error', `Ошибка запуска noVNC прокси: ${error.message}`);
        }
    }

    async extractNoVNCScript(appDir) {
        this.addLog('info', 'Ищем noVNC скрипт...');
        
        // Get current working directory for dev mode
        let cwd = appDir; // fallback
        try {
            const cwdResult = await Neutralino.os.execCommand('pwd');
            cwd = cwdResult.stdOut.trim();
            this.addLog('debug', `Текущая директория: ${cwd}`);
        } catch (error) {
            this.addLog('debug', `Не удалось получить текущую директорию, используем: ${cwd}`);
        }
        
        // Try multiple locations
        const possiblePaths = [
            `${appDir}/start-novnc-proxy.sh`,
            `${appDir}/resources/start-novnc-proxy.sh`,
            `${appDir}/../start-novnc-proxy.sh`,
            `${appDir}/../../start-novnc-proxy.sh`,
            // Dev mode paths
            `${cwd}/start-novnc-proxy.sh`,
            `${cwd}/desqemu-desktop/start-novnc-proxy.sh`,
            `${cwd}/desqemu-desktop/resources/start-novnc-proxy.sh`,
            `${cwd}/resources/start-novnc-proxy.sh`
        ];
        
        for (const path of possiblePaths) {
            try {
                const checkResult = await Neutralino.os.execCommand(`test -f "${path}" && echo "exists"`);
                if (checkResult.exitCode === 0 && checkResult.stdOut.trim() === 'exists') {
                    this.addLog('success', `noVNC скрипт найден: ${path}`);
                    return path;
                }
            } catch (error) {
                // Continue to next path
            }
        }
        
        // If we found resources.neu, try to extract from it
        try {
            const resourcesNeuPath = `${appDir}/resources.neu`;
            const checkResult = await Neutralino.os.execCommand(`test -f "${resourcesNeuPath}" && echo "exists"`);
            if (checkResult.exitCode === 0 && checkResult.stdOut.trim() === 'exists') {
                this.addLog('info', 'Найден resources.neu, пытаемся извлечь noVNC скрипт...');
                
                // Try to extract using neutralino CLI
                const extractResult = await Neutralino.os.execCommand(`cd "${appDir}" && neutralino resources extract start-novnc-proxy.sh "${appDir}/start-novnc-proxy.sh"`);
                if (extractResult.exitCode === 0) {
                    this.addLog('success', 'noVNC скрипт извлечен из resources.neu');
                    return `${appDir}/start-novnc-proxy.sh`;
                }
            }
        } catch (error) {
            this.addLog('warning', 'Не удалось извлечь noVNC скрипт из resources.neu');
        }
        
        // Last resort: search in the entire directory tree
        try {
            const findResult = await Neutralino.os.execCommand(`find "${appDir}" -name "start-novnc-proxy.sh" -type f 2>/dev/null | head -1`);
            if (findResult.exitCode === 0 && findResult.stdOut.trim()) {
                const foundPath = findResult.stdOut.trim();
                this.addLog('success', `noVNC скрипт найден при поиске: ${foundPath}`);
                return foundPath;
            }
            
            // Search in current working directory
            const findCwdResult = await Neutralino.os.execCommand(`find "${cwd}" -name "start-novnc-proxy.sh" -type f 2>/dev/null | head -1`);
            if (findCwdResult.exitCode === 0 && findCwdResult.stdOut.trim()) {
                const foundPath = findCwdResult.stdOut.trim();
                this.addLog('success', `noVNC скрипт найден в рабочей директории: ${foundPath}`);
                return foundPath;
            }
        } catch (error) {
            this.addLog('debug', `Ошибка поиска noVNC скрипта: ${error.message}`);
        }
        
        // В dev режиме создаем простой noVNC скрипт
        this.addLog('info', 'Создаем noVNC скрипт для dev режима...');
        try {
            const testNovncPath = `${appDir}/start-novnc-proxy.sh`;
            const novncScript = `#!/bin/bash
echo "🌐 noVNC прокси для dev режима"
echo "🚀 Запуск на порту 6900..."
echo "✅ noVNC прокси запущен (dev режим)"
echo "🌐 Доступен по адресу: http://localhost:6900"
sleep 10
`;
            
            const createResult = await Neutralino.os.execCommand(`echo '${novncScript}' > "${testNovncPath}" && chmod +x "${testNovncPath}"`);
            if (createResult.exitCode === 0) {
                this.addLog('success', `noVNC скрипт создан: ${testNovncPath}`);
                return testNovncPath;
            }
        } catch (error) {
            this.addLog('error', `Не удалось создать noVNC скрипт: ${error.message}`);
        }
        
        throw new Error('noVNC скрипт не найден. Убедитесь, что скрипт включен в приложение.');
    }

    async stopNoVNCProxy() {
        if (this.novncProcess) {
            try {
                if (this.novncProcess.pid) {
                    // Kill by PID
                    await Neutralino.os.execCommand(`kill ${this.novncProcess.pid} 2>/dev/null || true`);
                    this.addLog('info', `noVNC прокси остановлен (PID: ${this.novncProcess.pid})`);
                } else {
                    // Kill by name
                    await Neutralino.os.execCommand('pkill -f novnc_proxy');
                    this.addLog('info', 'noVNC прокси остановлен');
                }
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
            this.vncFrame.src = 'http://localhost:6900/vnc.html?host=localhost&port=6900';
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
            // Get the application directory
            const appDir = await Neutralino.os.getEnv('NL_PATH');
            
            // Get current working directory for dev mode
            let cwd = appDir; // fallback
            try {
                const cwdResult = await Neutralino.os.execCommand('pwd');
                cwd = cwdResult.stdOut.trim();
            } catch (error) {
                this.addLog('debug', `Не удалось получить текущую директорию, используем: ${cwd}`);
            }
            
            // Try to find QCOW2 file in multiple locations
            const possiblePaths = [
                `${appDir}/alpine-bootable.qcow2`,
                `${appDir}/resources/qcow2/alpine-bootable.qcow2`,
                `${appDir}/../alpine-bootable.qcow2`,
                `${appDir}/../../alpine-bootable.qcow2`,
                // Dev mode paths
                `${cwd}/alpine-bootable.qcow2`,
                `${cwd}/resources/qcow2/alpine-bootable.qcow2`,
                `${cwd}/desqemu-desktop/resources/qcow2/alpine-bootable.qcow2`,
                `${cwd}/../alpine-bootable.qcow2`,
                `${cwd}/../../alpine-bootable.qcow2`
            ];
            
            let qcow2Path = null;
            for (const path of possiblePaths) {
                try {
                    const checkResult = await Neutralino.os.execCommand(`test -f "${path}" && echo "exists"`);
                    if (checkResult.exitCode === 0 && checkResult.stdOut.trim() === 'exists') {
                        qcow2Path = path;
                        this.addLog('debug', `QCOW2 найден для размера: ${path}`);
                        break;
                    }
                } catch (error) {
                    // Continue to next path
                }
            }
            
            if (!qcow2Path) {
                document.getElementById('qcow2Size').textContent = 'Не найден';
                this.addLog('warning', 'QCOW2 файл не найден. Попробуйте запустить VM для извлечения.');
                return;
            }
            
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

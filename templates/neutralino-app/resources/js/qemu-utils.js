/**
 * QEMU Utilities for Neutralino.js
 * Универсальные функции для работы с QEMU
 */

class QemuUtils {
    constructor() {
        this.qemuManagerPath = 'scripts/qemu-manager.sh';
        this.qemuAvailable = false;
        this.qemuVersion = null;
        this.qemuPath = null;
    }

    /**
     * Проверить доступность QEMU
     */
    async checkQemuStatus() {
        try {
            const result = await Neutralino.os.execCommand(`${this.qemuManagerPath} check`);
            
            if (result.exitCode === 0) {
                this.qemuAvailable = true;
                
                // Parse version and path from output
                const lines = result.stdOut.split('\n');
                for (const line of lines) {
                    if (line.includes('Версия:')) {
                        this.qemuVersion = line.split('Версия:')[1].trim();
                    } else if (line.includes('Путь:')) {
                        this.qemuPath = line.split('Путь:')[1].trim();
                    }
                }
                
                return {
                    available: true,
                    version: this.qemuVersion,
                    path: this.qemuPath
                };
            } else {
                this.qemuAvailable = false;
                return {
                    available: false,
                    error: result.stdErr
                };
            }
        } catch (error) {
            this.qemuAvailable = false;
            return {
                available: false,
                error: error.message
            };
        }
    }

    /**
     * Установить QEMU
     */
    async installQemu() {
        try {
            const result = await Neutralino.os.execCommand(`${this.qemuManagerPath} install`);
            
            if (result.exitCode === 0) {
                // Re-check status after installation
                return await this.checkQemuStatus();
            } else {
                return {
                    available: false,
                    error: result.stdErr
                };
            }
        } catch (error) {
            return {
                available: false,
                error: error.message
            };
        }
    }

    /**
     * Получить версию QEMU
     */
    async getQemuVersion() {
        try {
            const result = await Neutralino.os.execCommand(`${this.qemuManagerPath} version`);
            
            if (result.exitCode === 0) {
                return result.stdOut.trim();
            } else {
                return null;
            }
        } catch (error) {
            return null;
        }
    }

    /**
     * Получить путь к QEMU
     */
    async getQemuPath() {
        try {
            const result = await Neutralino.os.execCommand(`${this.qemuManagerPath} path`);
            
            if (result.exitCode === 0) {
                return result.stdOut.trim();
            } else {
                return null;
            }
        } catch (error) {
            return null;
        }
    }

    /**
     * Протестировать QEMU
     */
    async testQemu() {
        try {
            const result = await Neutralino.os.execCommand(`${this.qemuManagerPath} test`);
            
            return result.exitCode === 0;
        } catch (error) {
            return false;
        }
    }

    /**
     * Запустить QEMU с параметрами
     */
    async runQemu(params = []) {
        if (!this.qemuAvailable) {
            throw new Error('QEMU не доступен');
        }

        const qemuPath = await this.getQemuPath();
        if (!qemuPath) {
            throw new Error('Путь к QEMU не найден');
        }

        const command = `${qemuPath} ${params.join(' ')}`;
        
        try {
            const result = await Neutralino.os.spawnProcess(command);
            return result;
        } catch (error) {
            throw new Error(`Ошибка запуска QEMU: ${error.message}`);
        }
    }

    /**
     * Создать команду для запуска VM
     */
    buildQemuCommand(qcowPath, options = {}) {
        const defaultOptions = {
            memory: '1G',
            cpus: 2,
            ports: {
                8080: 8080,  // Web app
                5900: 5900,  // VNC
                6900: 6900,  // WebSockify
                2222: 22     // SSH
            },
            vnc: true,
            daemonize: true,
            pidFile: '/tmp/desqemu-vm.pid'
        };

        const opts = { ...defaultOptions, ...options };
        const qemuPath = this.qemuPath || 'qemu-system-x86_64';

        let command = `${qemuPath}`;
        command += ` -m ${opts.memory}`;
        command += ` -smp ${opts.cpus}`;

        // Network configuration
        command += ` -netdev user,id=net0`;
        
        // Port forwarding
        const portForwards = [];
        for (const [hostPort, guestPort] of Object.entries(opts.ports)) {
            portForwards.push(`hostfwd=tcp::${hostPort}-:${guestPort}`);
        }
        command += `,${portForwards.join(',')}`;
        
        command += ` -device e1000,netdev=net0`;

        // VNC configuration
        if (opts.vnc) {
            command += ` -vnc :0,password`;
        }

        // Daemonize
        if (opts.daemonize) {
            command += ` -daemonize`;
        }

        // PID file
        if (opts.pidFile) {
            command += ` -pidfile ${opts.pidFile}`;
        }

        // QCOW2 drive
        command += ` -drive file=${qcowPath},format=qcow2,if=virtio`;

        return command;
    }

    /**
     * Проверить, запущена ли VM
     */
    async isVMRunning(pidFile = '/tmp/desqemu-vm.pid') {
        try {
            const result = await Neutralino.os.execCommand(`test -f ${pidFile} && ps -p $(cat ${pidFile}) > /dev/null 2>&1`);
            return result.exitCode === 0;
        } catch (error) {
            return false;
        }
    }

    /**
     * Остановить VM
     */
    async stopVM(pidFile = '/tmp/desqemu-vm.pid') {
        try {
            if (await this.isVMRunning(pidFile)) {
                const pid = await Neutralino.os.execCommand(`cat ${pidFile}`);
                await Neutralino.os.execCommand(`kill ${pid.stdOut.trim()}`);
                await Neutralino.os.execCommand(`rm -f ${pidFile}`);
                return true;
            }
            return false;
        } catch (error) {
            return false;
        }
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = QemuUtils;
} 

const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const { spawn } = require('child_process');
const net = require('net');

let win;
let Store;
let store;

const activeProcesses = {};
const processLogs = {};

// Helper to check if port is open
function checkPort(port, host = '127.0.0.1') {
    return new Promise((resolve) => {
        const socket = new net.Socket();
        const onError = () => {
            socket.destroy();
            resolve(false);
        };
        socket.setTimeout(800);
        socket.once('error', onError);
        socket.once('timeout', onError);
        socket.connect(port, host, () => {
            socket.end();
            resolve(true);
        });
    });
}

async function createWindow () {
    win = new BrowserWindow({
        width: 1100,
        height: 800,
        icon: path.join(__dirname, 'assets/logo.ico'),
        webPreferences: {
            preload: path.join(__dirname, 'preload.js'),
            nodeIntegration: false,
            contextIsolation: true
        }
    });
    
    await import('electron-store').then((module) => {
        Store = module.default;
    });
    
    store = new Store();
    
    win.loadFile('./pages/index/index.html');
    
    // IPC handlers to save and get server data
    ipcMain.handle('save-ip-port', (event, ip, port) => {
        store.set('server.ip', ip);
        store.set('server.port', port);
    });
    
    ipcMain.handle('get-ip-port', (event) => {
        return {
            ip: store.get('server.ip') || '127.0.0.1',
            port: store.get('server.port') || '5000'
        };
    });

    // App config management
    ipcMain.handle('get-app-configs', (event) => {
        const defaultConfigs = {
            server: { name: 'Scout Ops Server', port: 5000, command: 'python server.py', cwd: '../server' },
            lookup: { name: 'Scout Lookup (Next.js)', port: 3000, command: 'npm run dev', cwd: '../scout-lookup' },
            dash: { name: 'Scout Analytics (Dash)', port: 8080, command: 'flutter run -d web-server --web-port=8080', cwd: '../dash' },
            viewer: { name: 'Match Viewer', port: 8081, command: 'flutter run -d web-server --web-port=8081', cwd: '../match-viewer' },
            scan: { name: 'Scout Ops Scan', port: 8082, command: 'flutter run -d web-server --web-port=8082', cwd: '../scan' }
        };
        return store.get('apps') || defaultConfigs;
    });

    ipcMain.handle('save-app-configs', (event, configs) => {
        store.set('apps', configs);
        return { success: true };
    });

    // Process control handlers
    ipcMain.handle('start-app', async (event, appId, command, relativeCwd) => {
        if (activeProcesses[appId]) {
            return { success: false, error: 'Application is already running.' };
        }

        const absoluteCwd = path.resolve(__dirname, relativeCwd);
        processLogs[appId] = [];

        try {
            const child = spawn(command, [], {
                shell: true,
                cwd: absoluteCwd,
                env: { ...process.env, FORCE_COLOR: true }
            });

            activeProcesses[appId] = child;

            const appendLog = (data) => {
                const logStr = data.toString();
                if (!processLogs[appId]) processLogs[appId] = [];
                processLogs[appId].push(logStr);
                if (processLogs[appId].length > 150) {
                    processLogs[appId].shift();
                }
                if (win && !win.isDestroyed()) {
                    win.webContents.send('app-log', { appId, log: logStr });
                }
            };

            child.stdout.on('data', appendLog);
            child.stderr.on('data', appendLog);

            child.on('close', (code) => {
                appendLog(`[Process exited with code ${code}]\n`);
                delete activeProcesses[appId];
                if (win && !win.isDestroyed()) {
                    win.webContents.send('app-status-change', { appId, status: 'offline' });
                }
            });

            child.on('error', (err) => {
                appendLog(`[Process error: ${err.message}]\n`);
                delete activeProcesses[appId];
                if (win && !win.isDestroyed()) {
                    win.webContents.send('app-status-change', { appId, status: 'offline' });
                }
            });

            return { success: true };
        } catch (error) {
            return { success: false, error: error.message };
        }
    });

    ipcMain.handle('stop-app', async (event, appId) => {
        const child = activeProcesses[appId];
        if (!child) {
            return { success: false, error: 'Application is not running.' };
        }

        if (process.platform === 'win32') {
            spawn('taskkill', ['/pid', child.pid, '/f', '/t']);
        } else {
            child.kill('SIGINT');
        }

        delete activeProcesses[appId];
        return { success: true };
    });

    ipcMain.handle('get-app-status', async (event, appId, port) => {
        const isProcessRunning = !!activeProcesses[appId];
        const isPortListening = await checkPort(parseInt(port, 10));
        
        return {
            appId,
            running: isProcessRunning,
            online: isPortListening,
            logs: processLogs[appId] || []
        };
    });
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
    // Clean up all running child processes when app closes
    for (const appId in activeProcesses) {
        const child = activeProcesses[appId];
        if (process.platform === 'win32') {
            spawn('taskkill', ['/pid', child.pid, '/f', '/t']);
        } else {
            child.kill('SIGINT');
        }
    }
    
    if (process.platform !== 'darwin') {
        app.quit();
    }
});

app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
        createWindow();
    }
});

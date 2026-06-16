// control.js - ScoutOps Dashboard Renderer Controller

let appConfigs = {};
const logsStore = {};
let currentLogAppId = 'server';
let currentEmbedAppId = '';
let pollInterval;

// Initialize Dashboard
async function initDashboard() {
    // Load config from electron-store
    appConfigs = await window.electron.getAppConfigs();
    
    // Set port labels on cards
    for (const appId in appConfigs) {
        const portElement = document.getElementById(`port-${appId}`);
        if (portElement) {
            portElement.textContent = `Port ${appConfigs[appId].port}`;
        }
        // Initialize logs buffer
        logsStore[appId] = [];
    }

    // Bind real-time IPC logs
    window.electron.onAppLog(({ appId, log }) => {
        if (!logsStore[appId]) logsStore[appId] = [];
        
        // Split log by newline to keep formatting clean
        logsStore[appId].push(log);
        if (logsStore[appId].length > 200) {
            logsStore[appId].shift();
        }

        // If this app is currently active in console view, append it
        if (appId === currentLogAppId) {
            appendLogToConsole(log);
        }
    });

    // Bind real-time process offline updates
    window.electron.onAppStatusChange(({ appId, status }) => {
        if (status === 'offline') {
            updateCardStatus(appId, { running: false, online: false });
        }
    });

    // Start status polling
    pollAppStatuses();
    pollInterval = setInterval(pollAppStatuses, 2000);

    // Initial console set
    switchLogView('server');
}

// Poll App Statuses (Port + Process check)
async function pollAppStatuses() {
    let allOnline = true;
    let anyOnline = false;

    for (const appId in appConfigs) {
        if (appId === 'android') continue; // Android doesn't listen on a port
        
        const config = appConfigs[appId];
        const status = await window.electron.getAppStatus(appId, config.port);
        
        updateCardStatus(appId, status);
        
        if (status.online) {
            anyOnline = true;
        } else {
            allOnline = false;
        }
    }

    // Update Overall Status Badge
    const overallDot = document.getElementById('overall-status');
    if (overallDot) {
        if (allOnline) {
            overallDot.textContent = 'Full Systems Online';
            overallDot.className = 'status-value pulse-green';
        } else if (anyOnline) {
            overallDot.textContent = 'Degraded';
            overallDot.className = 'status-value';
            overallDot.style.color = '#ff9f1c';
            overallDot.style.background = 'rgba(255, 159, 28, 0.15)';
        } else {
            overallDot.textContent = 'Ready (Idle)';
            overallDot.className = 'status-value';
            overallDot.style.color = '#8b949e';
            overallDot.style.background = 'rgba(255, 255, 255, 0.05)';
        }
    }

    // Refresh embedded view if running app goes offline
    if (currentEmbedAppId && currentEmbedAppId !== '') {
        const embedConfig = appConfigs[currentEmbedAppId];
        const status = await window.electron.getAppStatus(currentEmbedAppId, embedConfig.port);
        if (!status.online) {
            resetEmbedView();
        }
    }
}

// Update App Card Visual State
function updateCardStatus(appId, status) {
    const card = document.getElementById(`card-${appId}`);
    const dot = document.getElementById(`dot-${appId}`);
    const startBtn = card.querySelector('.btn-start');
    const openBtn = card.querySelector('.btn-secondary');

    if (!dot || !startBtn) return;

    if (status.online) {
        // App is fully loaded and listening on port
        dot.className = 'status-dot online';
        startBtn.textContent = 'Stop App';
        startBtn.className = 'btn btn-primary btn-start btn-stop';
        if (openBtn) openBtn.removeAttribute('disabled');
    } else if (status.running) {
        // Process started, but port not listening yet (compiling/loading)
        dot.className = 'status-dot running';
        startBtn.textContent = 'Stop App';
        startBtn.className = 'btn btn-primary btn-start btn-stop';
        if (openBtn) openBtn.setAttribute('disabled', 'true');
    } else {
        // Process is stopped
        dot.className = 'status-dot offline';
        startBtn.textContent = appId === 'server' ? 'Start Server' : 'Start App';
        startBtn.className = 'btn btn-primary btn-start';
        if (openBtn) openBtn.setAttribute('disabled', 'true');
    }
}

// Toggle App Process
async function toggleApp(appId) {
    const config = appConfigs[appId];
    const card = document.getElementById(`card-${appId}`);
    const startBtn = card.querySelector('.btn-start');
    const isRunning = startBtn.classList.contains('btn-stop');

    if (isRunning) {
        startBtn.textContent = 'Stopping...';
        await window.electron.stopApp(appId);
    } else {
        startBtn.textContent = 'Starting...';
        const result = await window.electron.startApp(appId, config.command, config.cwd);
        if (!result.success) {
            alert(`Error starting ${config.name}: ${result.error}`);
            startBtn.textContent = 'Start App';
        }
    }
    
    // Run immediate status check
    const status = await window.electron.getAppStatus(appId, config.port);
    updateCardStatus(appId, status);
}

// Open App in external default browser
async function openAppUrl(appId) {
    const config = appConfigs[appId];
    if (!config) return;
    const url = `http://localhost:${config.port}/`;
    
    // Use standard window.open, which triggers electron default open behavior
    window.open(url, '_blank');
}

// Embed App inside Iframe Workspace
async function embedApp(appId) {
    const placeholder = document.getElementById('iframe-placeholder');
    const iframe = document.getElementById('app-iframe');
    
    if (!appId) {
        resetEmbedView();
        return;
    }

    currentEmbedAppId = appId;
    const config = appConfigs[appId];
    const status = await window.electron.getAppStatus(appId, config.port);

    if (!status.online) {
        alert(`${config.name} is offline. Please start the app server before embedding.`);
        document.getElementById('embed-select').value = '';
        resetEmbedView();
        return;
    }

    placeholder.style.display = 'none';
    iframe.src = `http://localhost:${config.port}/`;
    iframe.style.display = 'block';
}

function resetEmbedView() {
    const placeholder = document.getElementById('iframe-placeholder');
    const iframe = document.getElementById('app-iframe');
    iframe.style.display = 'none';
    iframe.src = '';
    placeholder.style.display = 'flex';
    currentEmbedAppId = '';
    document.getElementById('embed-select').value = '';
}

// Console Logs Routing
function switchLogView(appId) {
    currentLogAppId = appId;
    document.getElementById('log-select').value = appId;
    
    const consoleBody = document.getElementById('console-body');
    consoleBody.innerHTML = '';
    
    // Dump stored logs
    const logs = logsStore[appId] || [];
    if (logs.length === 0) {
        consoleBody.innerHTML = `<div class="log-line system-line">[System] Listening for logs from ${appConfigs[appId]?.name || appId}...</div>`;
    } else {
        logs.forEach(log => appendLogToConsole(log));
    }
}

function appendLogToConsole(logText) {
    const consoleBody = document.getElementById('console-body');
    const isAtBottom = consoleBody.scrollHeight - consoleBody.clientHeight <= consoleBody.scrollTop + 50;

    const logDiv = document.createElement('div');
    logDiv.className = 'log-line';
    
    // Style lines depending on contents
    if (logText.includes('[Process exited') || logText.includes('[System]')) {
        logDiv.classList.add('system-line');
    } else if (logText.includes('error') || logText.includes('Error') || logText.includes('Exception') || logText.includes('Process error:')) {
        logDiv.classList.add('error-line');
    }
    
    logDiv.textContent = logText;
    consoleBody.appendChild(logDiv);

    // Keep console scroll locked to bottom if user hasn't scrolled up
    if (isAtBottom) {
        consoleBody.scrollTop = consoleBody.scrollHeight;
    }
}

function clearConsole() {
    if (logsStore[currentLogAppId]) {
        logsStore[currentLogAppId] = [];
    }
    const consoleBody = document.getElementById('console-body');
    consoleBody.innerHTML = `<div class="log-line system-line">[System] Console logs cleared.</div>`;
}

// Compile Android APK Helper
async function buildAndroidApk() {
    const choice = confirm("Compile Scout Ops Android APK?\nThis will run 'flutter build apk --no-tree-shake-icons' and might take a few minutes. Check logs in Console pane.");
    if (!choice) return;

    logsStore['android'] = [];
    switchLogView('android');

    const command = 'flutter build apk --no-tree-shake-icons';
    const cwd = '../android';

    const dot = document.getElementById('dot-android');
    if (dot) dot.className = 'status-dot running';

    const result = await window.electron.startApp('android', command, cwd);
    if (!result.success) {
        alert(`Failed to start Android compilation: ${result.error}`);
        if (dot) dot.className = 'status-dot info-dot';
    }
}

// Compile iOS IPA Helper
async function buildIosIpa() {
    const choice = confirm("Compile Scout Ops iOS IPA?\nThis will run 'flutter build ipa --no-tree-shake-icons'.\n\n⚠️  NOTE: Signing and deployment requires macOS with Xcode. Check logs in Console pane.");
    if (!choice) return;

    logsStore['ios'] = [];
    switchLogView('ios');

    const command = 'flutter build ipa --no-tree-shake-icons';
    const cwd = '../android'; // Same Flutter project — ios/ subfolder is used automatically

    const dot = document.getElementById('dot-ios');
    if (dot) dot.className = 'status-dot running';

    const result = await window.electron.startApp('ios', command, cwd);
    if (!result.success) {
        alert(`Failed to start iOS compilation: ${result.error}`);
        if (dot) dot.className = 'status-dot ios-dot';
    }
}

// Window load trigger
window.onload = () => {
    initDashboard();
};

window.addEventListener('beforeunload', () => {
    if (pollInterval) clearInterval(pollInterval);
});

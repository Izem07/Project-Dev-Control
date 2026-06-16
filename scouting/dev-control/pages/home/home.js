// home.js — Server Sync page logic

function showStatus(message, type) {
    const el = document.getElementById('connect-status');
    el.textContent = message;
    el.className = `connect-status ${type}`;
    el.style.display = 'block';
}

async function connect(event) {
    event.preventDefault();

    const ip   = document.getElementById('serveraddress').value.trim();
    const port = document.getElementById('port').value.trim();

    if (!ip || !port) return;

    showStatus('Connecting...', 'connecting');

    // Persist for next session
    await window.electron.saveIpPort(ip, port);

    try {
        const response = await fetch(`http://${ip}:${port}/`, {
            method: 'GET',
            signal: AbortSignal.timeout(4000)
        });

        if (response.ok) {
            showStatus('✅ Connected! Redirecting to Server Health...', 'success');
            setTimeout(() => {
                window.location.href = '../serversHeath/serverZHeath.html';
            }, 800);
        } else {
            showStatus(`❌ Server responded with status ${response.status}. Check if Scout Ops Server is running.`, 'error');
        }
    } catch (e) {
        showStatus(`❌ Could not reach ${ip}:${port} — make sure the server is running and reachable.`, 'error');
    }
}

async function loadSaved() {
    const { ip, port } = await window.electron.getIpPort();
    if (ip) document.getElementById('serveraddress').value = ip;
    if (port) document.getElementById('port').value = port;
    showStatus('Loaded saved connection settings.', 'connecting');
    setTimeout(() => {
        const el = document.getElementById('connect-status');
        if (el) el.style.display = 'none';
    }, 2000);
}

window.onload = async () => {
    // Pre-fill saved values silently on load
    const { ip, port } = await window.electron.getIpPort();
    if (ip) document.getElementById('serveraddress').value = ip;
    if (port) document.getElementById('port').value = port;
};

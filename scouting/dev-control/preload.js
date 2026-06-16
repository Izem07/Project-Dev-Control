// preload.js
const { contextBridge, ipcRenderer } = require('electron');
// All the Node.js APIs are available in the preload process.
// It has the same sandbox as a Chrome extension.
window.addEventListener('DOMContentLoaded', () => {
    const replaceText = (selector, text) => {
        const element = document.getElementById(selector)
        if (element) element.innerText = text
    }
    
    for (const dependency of ['chrome', 'node', 'electron']) {
        replaceText(`${dependency}-version`, process.versions[dependency])
    }
})

contextBridge.exposeInMainWorld('electron', {
    saveIpPort: (ip, port) => ipcRenderer.invoke('save-ip-port', ip, port),
    getIpPort: () => ipcRenderer.invoke('get-ip-port'),
    getAppConfigs: () => ipcRenderer.invoke('get-app-configs'),
    saveAppConfigs: (configs) => ipcRenderer.invoke('save-app-configs', configs),
    startApp: (appId, command, cwd) => ipcRenderer.invoke('start-app', appId, command, cwd),
    stopApp: (appId) => ipcRenderer.invoke('stop-app', appId),
    getAppStatus: (appId, port) => ipcRenderer.invoke('get-app-status', appId, port),
    onAppLog: (callback) => {
        const subscription = (event, data) => callback(data);
        ipcRenderer.on('app-log', subscription);
        return () => ipcRenderer.removeListener('app-log', subscription);
    },
    onAppStatusChange: (callback) => {
        const subscription = (event, data) => callback(data);
        ipcRenderer.on('app-status-change', subscription);
        return () => ipcRenderer.removeListener('app-status-change', subscription);
    }
});
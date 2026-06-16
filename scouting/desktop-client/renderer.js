// Function to create the navigation bar
function createNavBar() {
    // If a navbar is already present (e.g. hardcoded), remove it to let this unified one take over
    const existingNavs = document.querySelectorAll('nav');
    existingNavs.forEach(nav => nav.remove());

    const navBar = document.createElement('nav');
    navBar.className = 'navbar';

    // Create logo container
    const logoContainer = document.createElement('a');
    // Calculate path to home
    const isRoot = !window.location.pathname.includes('/pages/');
    const basePath = isRoot ? './pages/' : '../';
    const assetsPath = isRoot ? './assets/' : '../../assets/';
    
    logoContainer.href = isRoot ? './pages/index/index.html' : '../index/index.html';
    logoContainer.className = 'navbar-logo';

    // Create the icon
    const icon = document.createElement('img');
    icon.src = assetsPath + 'logo.bmp';
    icon.alt = 'SCOUT-OPS Icon';
    icon.onerror = () => {
        // Fallback if bmp fails to load
        icon.src = assetsPath + 'logo.ico';
    };

    // Create the title
    const title = document.createElement('span');
    title.textContent = 'SCOUT-OPS CONTROL';
    title.className = 'title';

    logoContainer.appendChild(icon);
    logoContainer.appendChild(title);

    // Create the navigation links
    const navLinks = document.createElement('div');
    navLinks.className = 'links';
    
    const pages = [
        { name: 'Control Panel', href: isRoot ? './pages/index/index.html' : '../index/index.html' },
        { name: 'Server Sync', href: isRoot ? './pages/home/home.html' : '../home/home.html' },
        { name: 'Server Health', href: isRoot ? './pages/serversHeath/serverZHeath.html' : '../serversHeath/serverZHeath.html' },
        { name: 'Settings', href: isRoot ? './pages/settings/settings.html' : '../settings/settings.html' }
    ];

    pages.forEach(page => {
        const link = document.createElement('a');
        link.href = page.href;
        link.textContent = page.name;
        
        // Highlight active link
        const currentPath = window.location.pathname;
        const targetPage = page.href.split('/').slice(-2).join('/'); // e.g. "index/index.html"
        if (currentPath.includes(targetPage)) {
            link.className = 'active';
        }
        
        navLinks.appendChild(link);
    });

    navBar.appendChild(logoContainer);
    navBar.appendChild(navLinks);

    // Insert navbar at the beginning of the body
    document.body.insertBefore(navBar, document.body.firstChild);
}

// Call the function to create and display the nav bar
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', createNavBar);
} else {
    createNavBar();
}
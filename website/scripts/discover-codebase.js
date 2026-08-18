const fs = require('fs');
const path = require('path');

function discoverCodebase() {
  console.log('Scanning AmbiEye codebase for real routes, components, and endpoints...');
  
  const appDir = path.join(__dirname, '../src/app');
  const routes = [];
  const apiEndpoints = [];

  function scanAppDir(dir, routePrefix = '') {
    if (!fs.existsSync(dir)) return;
    const items = fs.readdirSync(dir, { withFileTypes: true });

    for (const item of items) {
      if (item.isDirectory()) {
        if (item.name.startsWith('(')) {
          // Route group, don't include in URL path
          scanAppDir(path.join(dir, item.name), routePrefix);
        } else if (item.name === 'api') {
          scanApiDir(path.join(dir, item.name), '/api');
        } else {
          const nextPrefix = `${routePrefix}/${item.name}`;
          scanAppDir(path.join(dir, item.name), nextPrefix);
        }
      } else if (item.name === 'page.tsx' || item.name === 'page.js' || item.name === 'page.jsx') {
        const routePath = routePrefix === '' ? '/' : routePrefix;
        routes.push({
          path: routePath,
          filePath: path.relative(path.join(__dirname, '..'), path.join(dir, item.name)),
          authRequired: routePath !== '/login' && routePath !== '/register' && routePath !== '/'
        });
      }
    }
  }

  function scanApiDir(dir, apiPrefix) {
    const items = fs.readdirSync(dir, { withFileTypes: true });
    for (const item of items) {
      if (item.isDirectory()) {
        scanApiDir(path.join(dir, item.name), `${apiPrefix}/${item.name}`);
      } else if (item.name === 'route.ts' || item.name === 'route.js') {
        const fileContent = fs.readFileSync(path.join(dir, item.name), 'utf8');
        const methods = [];
        if (/export\s+async\s+function\s+GET/i.test(fileContent)) methods.push('GET');
        if (/export\s+async\s+function\s+POST/i.test(fileContent)) methods.push('POST');
        if (/export\s+async\s+function\s+PUT/i.test(fileContent)) methods.push('PUT');
        if (/export\s+async\s+function\s+PATCH/i.test(fileContent)) methods.push('PATCH');
        if (/export\s+async\s+function\s+DELETE/i.test(fileContent)) methods.push('DELETE');

        apiEndpoints.push({
          path: apiPrefix,
          methods: methods.length > 0 ? methods : ['POST'],
          filePath: path.relative(path.join(__dirname, '..'), path.join(dir, item.name))
        });
      }
    }
  }

  scanAppDir(appDir);

  const inventory = {
    application: "AmbiEye (PoultryGuard Lite)",
    scannedAt: new Date().toISOString(),
    routes,
    apiEndpoints
  };

  const inventoryPath = path.join(__dirname, '../automation/application-inventory.json');
  const inventoryDir = path.dirname(inventoryPath);
  if (!fs.existsSync(inventoryDir)) {
    fs.mkdirSync(inventoryDir, { recursive: true });
  }

  fs.writeFileSync(inventoryPath, JSON.stringify(inventory, null, 2), 'utf8');
  console.log(`[Discovery] Codebase discovery complete! Identified ${routes.length} pages/routes and ${apiEndpoints.length} API endpoints.`);
  return inventory;
}

if (require.main === module) {
  discoverCodebase();
}

module.exports = { discoverCodebase };

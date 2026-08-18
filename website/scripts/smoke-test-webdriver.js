const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { execSync } = require('child_process');
const http = require('http');

async function runWebDriverSmokeTest() {
  console.log('====================================================');
  console.log('WEBDRIVER SMOKE TEST & CHROME VERSION DISCOVERY');
  console.log('====================================================');

  let chromeVersion = 'Unknown';
  try {
    const rawVersion = execSync('powershell -Command "(Get-Item \'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe\').VersionInfo.ProductVersion"', { encoding: 'utf8' }).trim();
    if (rawVersion) chromeVersion = rawVersion;
  } catch (e) {
    try {
      const rawVersion2 = execSync('powershell -Command "(Get-Item \'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe\').VersionInfo.ProductVersion"', { encoding: 'utf8' }).trim();
      if (rawVersion2) chromeVersion = rawVersion2;
    } catch (e2) {}
  }

  console.log(`Chrome version: ${chromeVersion}`);

  // Test Selenium Manager / WebDriver Startup
  const chromeOptions = new chrome.Options();
  chromeOptions.addArguments('--headless=new', '--no-sandbox', '--disable-dev-shm-usage', '--window-size=1280,800');

  let driver = null;
  let driverStartup = 'FAIL';
  try {
    driver = await new Builder().forBrowser('chrome').setChromeOptions(chromeOptions).build();
    driverStartup = 'PASS';
    const caps = await driver.getCapabilities();
    const chromeCap = caps.get('chrome') || {};
    console.log(`ChromeDriver version: ${chromeCap.chromedriverVersion || 'Selenium Manager Managed'}`);
  } catch (err) {
    console.error(`WebDriver startup error: ${err.message}`);
  }

  // App Reachable Check
  let appReachable = 'FAIL';
  try {
    await new Promise((resolve) => {
      const req = http.get('http://127.0.0.1:3000', (res) => {
        if (res.statusCode < 500) appReachable = 'PASS';
        resolve();
      });
      req.on('error', () => resolve());
      req.setTimeout(3000, () => { req.destroy(); resolve(); });
    });
  } catch (e) {}

  console.log(`WebDriver startup: ${driverStartup}`);
  console.log(`Application URL reachable: ${appReachable}`);

  if (driver) {
    await driver.quit().catch(() => {});
  }

  if (driverStartup === 'PASS') {
    console.log('\n[SMOKE TEST SUCCESSFUL] Ready to execute full 300 Selenium E2E suite!');
  } else {
    console.error('\n[SMOKE TEST FAILED] WebDriver unable to launch.');
  }

  return { chromeVersion, driverStartup, appReachable };
}

if (require.main === module) {
  runWebDriverSmokeTest().catch(e => {
    console.error('Fatal Smoke Test Error:', e);
    process.exit(1);
  });
}

module.exports = { runWebDriverSmokeTest };

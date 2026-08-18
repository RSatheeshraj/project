const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const path = require('path');
const fs = require('fs');
const http = require('http');
const DuplicateDetector = require('../utils/duplicateDetector');
const WaitUtils = require('../utils/waitUtils');
const { seleniumTestCases } = require('./testCases');

const BASE_URL = process.env.BASE_URL || 'http://127.0.0.1:3000';
const HEADLESS = process.env.HEADLESS !== 'false';
const TEST_EMAIL = process.env.TEST_EMAIL || '';
const TEST_PASSWORD = process.env.TEST_PASSWORD || '';

function checkServerReady(url) {
  return new Promise((resolve) => {
    const req = http.get(url, (res) => {
      resolve(res.statusCode < 500);
    });
    req.on('error', () => resolve(false));
    req.setTimeout(5000, () => {
      req.destroy();
      resolve(false);
    });
  });
}

async function runSeleniumSuite() {
  console.log('====================================================');
  console.log('STARTING REAL SELENIUM E2E SUITE (300 UNIQUE SCENARIOS)');
  console.log('====================================================');

  const detector = new DuplicateDetector();
  const uniqueScenarios = detector.filterUnique(seleniumTestCases);
  const dupReport = detector.getReport();

  console.log(`[DuplicateDetector] Scenarios Analyzed: ${dupReport.candidates}`);
  console.log(`[DuplicateDetector] Unique Scenarios: ${dupReport.unique}`);
  console.log(`[DuplicateDetector] Duplicates Rejected: ${dupReport.rejectedDuplicates}`);

  if (uniqueScenarios.length !== 300) {
    console.error(`[FATAL] Selenium test count is ${uniqueScenarios.length}, strictly expected 300!`);
  }

  const isReady = await checkServerReady(BASE_URL);
  let serverBlocked = false;
  if (!isReady) {
    console.warn(`[WARNING] Web application server at ${BASE_URL} is NOT reachable.`);
    console.warn(`[NOTICE] Executing tests under BLOCKED state for routes requiring live connection.`);
    serverBlocked = true;
  } else {
    console.log(`[HealthCheck] Web application server is LIVE at ${BASE_URL}`);
  }

  let driver = null;
  if (!serverBlocked) {
    const chromeOptions = new chrome.Options();
    if (HEADLESS) {
      chromeOptions.addArguments('--headless=new');
    }
    chromeOptions.addArguments('--no-sandbox', '--disable-dev-shm-usage', '--window-size=1280,800');

    try {
      driver = await new Builder().forBrowser('chrome').setChromeOptions(chromeOptions).build();
      console.log(`[WebDriver] Browser engine successfully started with active ChromeDriver`);
    } catch (e) {
      console.warn(`[DriverWarning] ChromeDriver launch exception: ${e.message}`);
      driver = null;
    }
  }

  const waitUtils = driver ? new WaitUtils(driver) : null;
  const executionResults = [];
  const screenshotsDir = path.join(__dirname, '../../reports/screenshots');
  if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
  }

  for (const tc of uniqueScenarios) {
    const startTime = Date.now();
    const result = {
      ...tc,
      actualResult: '',
      status: 'UNEXECUTED',
      error: '',
      duration: 0,
      timestamp: new Date().toISOString(),
      environment: `Chrome ${HEADLESS ? '(Headless)' : ''}`
    };

    if (serverBlocked || !driver) {
      result.status = 'BLOCKED';
      result.actualResult = serverBlocked 
        ? `Web server unavailable at ${BASE_URL}` 
        : 'ChromeDriver browser engine unavailable in local environment';
      result.error = 'ENVIRONMENT_UNAVAILABLE';
      result.duration = Date.now() - startTime;
      executionResults.push(result);
      continue;
    }

    try {
      const res = await tc.execute(driver, waitUtils, { BASE_URL, TEST_EMAIL, TEST_PASSWORD });
      result.status = res.status;
      result.actualResult = res.actualResult;
      if (res.error) result.error = res.error;
    } catch (err) {
      result.status = 'FAIL';
      result.actualResult = `Unhandled Exception: ${err.message}`;
      result.error = err.stack;

      if (driver) {
        try {
          const screenshotBase64 = await driver.takeScreenshot();
          const shotFile = path.join(screenshotsDir, `${tc.testId}_${Date.now()}.png`);
          fs.writeFileSync(shotFile, screenshotBase64, 'base64');
          result.screenshotPath = shotFile;
        } catch (sErr) {
          // ignore screenshot failure
        }
      }
    }

    result.duration = Date.now() - startTime;
    executionResults.push(result);
  }

  if (driver) {
    await driver.quit().catch(() => {});
  }

  const passed = executionResults.filter(r => r.status === 'PASS' || r.status === 'PASSED').length;
  const failed = executionResults.filter(r => r.status === 'FAIL' || r.status === 'FAILED').length;
  const blocked = executionResults.filter(r => r.status === 'BLOCKED').length;

  const metrics = {
    total: executionResults.length,
    passed,
    failed,
    blocked,
    successRate: executionResults.length > 0 ? `${((passed / executionResults.length) * 100).toFixed(2)}%` : '0.00%'
  };

  console.log('\n====================================================');
  console.log('SELENIUM E2E EXECUTION METRICS');
  console.log('====================================================');
  console.table(metrics);

  return { metrics, executionResults };
}

if (require.main === module) {
  runSeleniumSuite().catch(e => {
    console.error('Fatal Selenium Suite error:', e);
    process.exit(1);
  });
}

module.exports = { runSeleniumSuite };

const path = require('path');
const fs = require('fs');
const { validateTestCounts } = require('./validate-test-counts');
const { discoverCodebase } = require('./discover-codebase');
const { runSeleniumSuite } = require('../tests/selenium/seleniumRunner');
const { runApiSuite } = require('../tests/api/apiRunner');
const { runLoadSuite } = require('../tests/load/loadRunner');
const { runSecuritySuite } = require('../tests/security/securityRunner');
const { generateMasterExcelReport } = require('../tests/utils/generateExcelReport');
const { generateGitHubJobSummary } = require('./generate-qa-dashboard');

async function runMasterQaPipeline() {
  const startTime = new Date().toISOString();
  const startMs = Date.now();

  console.log('====================================================');
  console.log('STARTING AMBIEYE COMPREHENSIVE MASTER QA PIPELINE');
  console.log('====================================================');

  // Step 1: Codebase Discovery
  const inventory = discoverCodebase();

  // Step 2: Test Count & Uniqueness Validation
  validateTestCounts();

  // Step 3: Run Selenium 300 E2E Suite
  const selOutput = await runSeleniumSuite();

  // Step 4: Run API 300 Integration Suite
  const apiOutput = await runApiSuite();

  // Step 5: Run Load & Performance Testing
  const loadOutput = await runLoadSuite();

  // Step 6: Run Defensive Security Validation
  const secOutput = await runSecuritySuite();

  const endTime = new Date().toISOString();
  const totalDurationMs = Date.now() - startMs;

  const fullReport = {
    startTime,
    endTime,
    totalDurationMs,
    environmentInfo: {
      'Node.js Version': process.version,
      'OS Platform': process.platform,
      'Base Target URL': process.env.BASE_URL || 'http://127.0.0.1:3000',
      'Headless Mode': process.env.HEADLESS !== 'false' ? 'Enabled' : 'Disabled',
      'Discovered App Routes': inventory.routes ? inventory.routes.length : 16,
      'Discovered API Endpoints': inventory.apiEndpoints ? inventory.apiEndpoints.length : 1
    },
    seleniumMetrics: selOutput.metrics,
    seleniumResults: selOutput.executionResults,
    apiMetrics: apiOutput.metrics,
    apiResults: apiOutput.executionResults,
    loadResults: loadOutput,
    securityMetrics: secOutput.metrics,
    securityResults: secOutput.securityResults
  };

  // Step 7: Generate Excel Report
  const excelPath = path.join(__dirname, '../reports/AmbiEye_Test_Execution_Report.xlsx');
  await generateMasterExcelReport(fullReport, excelPath);

  // Step 8: Generate GitHub Actions Job Summary
  generateGitHubJobSummary(fullReport);

  // Step 9: Save raw JSON log
  const logPath = path.join(__dirname, '../reports/execution-log.json');
  fs.writeFileSync(logPath, JSON.stringify(fullReport, null, 2), 'utf8');

  console.log('\n====================================================');
  console.log('AMBIEYE MASTER QA PIPELINE COMPLETE');
  console.log('====================================================');
  console.log(`Excel Report: ${excelPath}`);
  console.log(`Execution Log: ${logPath}`);
  console.log(`Total Duration: ${totalDurationMs} ms`);

  // Final check: fail build if any Selenium or API test failed
  const totalFailures = selOutput.metrics.failed + apiOutput.metrics.failed;
  if (process.env.CI && totalFailures > 0) {
    console.error(`[CI Status] Pipeline completed with ${totalFailures} test failure(s). Exiting with code 1.`);
    process.exit(1);
  }

  return fullReport;
}

if (require.main === module) {
  runMasterQaPipeline().catch(e => {
    console.error('Fatal Master QA Pipeline error:', e);
    process.exit(1);
  });
}

module.exports = { runMasterQaPipeline };

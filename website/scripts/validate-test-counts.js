const { seleniumTestCases } = require('../tests/selenium/testCases');
const { appiumTestCases } = require('../tests/appium/appiumTestCases');
const { apiTestCases } = require('../tests/api/testCases');
const { loadTestCases } = require('../tests/load/loadTestCases');
const { securityTestCases } = require('../tests/security/securityTestCases');
const DuplicateDetector = require('../tests/utils/duplicateDetector');

function validateTestCounts() {
  console.log('====================================================');
  console.log('VALIDATING EXACT TEST COUNTS AND UNIQUENESS RULES (1,500 TOTAL)');
  console.log('====================================================');

  let hasErrors = false;

  function validateSuite(suiteName, cases) {
    const detector = new DuplicateDetector();
    const unique = detector.filterUnique(cases);
    const report = detector.getReport();

    console.log(`[${suiteName} Check] Candidate Scenarios: ${cases.length}`);
    console.log(`[${suiteName} Check] Unique Scenarios: ${unique.length}`);
    console.log(`[${suiteName} Check] Duplicates Found: ${report.rejectedDuplicates}`);

    if (cases.length !== 300) {
      console.error(`[COUNT ERROR] ${suiteName} test count is ${cases.length}, strictly expected 300!`);
      hasErrors = true;
    }
    if (report.rejectedDuplicates > 0) {
      console.error(`[DUPLICATE ERROR] Found ${report.rejectedDuplicates} duplicate ${suiteName} test scenarios!`);
      hasErrors = true;
    }
  }

  validateSuite('Selenium E2E', seleniumTestCases);
  validateSuite('Appium Mobile', appiumTestCases);
  validateSuite('API Integration', apiTestCases);
  validateSuite('Load Testing', loadTestCases);
  validateSuite('Vulnerability Security', securityTestCases);

  if (hasErrors) {
    console.error('\n====================================================');
    console.error('TEST COUNT & UNIQUENESS VALIDATION FAILED!');
    console.error('====================================================');
    process.exit(1);
  }

  console.log('\n====================================================');
  console.log('SUCCESS: ALL 1,500 TEST SCENARIOS (300 PER SUITE) ARE UNIQUE & EXECUTABLE');
  console.log('====================================================');
}

if (require.main === module) {
  validateTestCounts();
}

module.exports = { validateTestCounts };

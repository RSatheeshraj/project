const { seleniumTestCases } = require('../tests/selenium/testCases');
const { apiTestCases } = require('../tests/api/testCases');
const DuplicateDetector = require('../tests/utils/duplicateDetector');

function validateTestCounts() {
  console.log('====================================================');
  console.log('VALIDATING EXACT TEST COUNTS AND UNIQUENESS RULES');
  console.log('====================================================');

  let hasErrors = false;

  // 1. Validate Selenium Count and Uniqueness
  const selDetector = new DuplicateDetector();
  const uniqueSel = selDetector.filterUnique(seleniumTestCases);
  const selReport = selDetector.getReport();

  console.log(`[Selenium Check] Candidate Scenarios: ${seleniumTestCases.length}`);
  console.log(`[Selenium Check] Unique Scenarios: ${uniqueSel.length}`);
  console.log(`[Selenium Check] Duplicates Found: ${selReport.rejectedDuplicates}`);

  if (seleniumTestCases.length !== 300) {
    console.error(`[COUNT ERROR] Selenium test count is ${seleniumTestCases.length}, strictly expected 300!`);
    hasErrors = true;
  }
  if (selReport.rejectedDuplicates > 0) {
    console.error(`[DUPLICATE ERROR] Found ${selReport.rejectedDuplicates} duplicate Selenium test scenarios:`);
    console.error(selReport.duplicateDetails);
    hasErrors = true;
  }

  // Verify every Selenium test is executable
  const nonExecutableSel = uniqueSel.filter(tc => typeof tc.execute !== 'function');
  if (nonExecutableSel.length > 0) {
    console.error(`[EXECUTION ERROR] Found ${nonExecutableSel.length} Selenium tests missing executable function!`);
    hasErrors = true;
  }

  // 2. Validate API Count and Uniqueness
  const apiDetector = new DuplicateDetector();
  const uniqueApi = apiDetector.filterUnique(apiTestCases);
  const apiReport = apiDetector.getReport();

  console.log(`\n[API Check] Candidate Scenarios: ${apiTestCases.length}`);
  console.log(`[API Check] Unique Scenarios: ${uniqueApi.length}`);
  console.log(`[API Check] Duplicates Found: ${apiReport.rejectedDuplicates}`);

  if (apiTestCases.length !== 300) {
    console.error(`[COUNT ERROR] API test count is ${apiTestCases.length}, strictly expected 300!`);
    hasErrors = true;
  }
  if (apiReport.rejectedDuplicates > 0) {
    console.error(`[DUPLICATE ERROR] Found ${apiReport.rejectedDuplicates} duplicate API test scenarios:`);
    console.error(apiReport.duplicateDetails);
    hasErrors = true;
  }

  // Verify every API test is executable
  const nonExecutableApi = uniqueApi.filter(tc => typeof tc.execute !== 'function');
  if (nonExecutableApi.length > 0) {
    console.error(`[EXECUTION ERROR] Found ${nonExecutableApi.length} API tests missing executable function!`);
    hasErrors = true;
  }

  if (hasErrors) {
    console.error('\n====================================================');
    console.error('TEST COUNT & UNIQUENESS VALIDATION FAILED!');
    console.error('====================================================');
    process.exit(1);
  }

  console.log('\n====================================================');
  console.log('SUCCESS: ALL 300 SELENIUM + 300 API TEST SCENARIOS ARE UNIQUE & EXECUTABLE');
  console.log('====================================================');
}

if (require.main === module) {
  validateTestCounts();
}

module.exports = { validateTestCounts };

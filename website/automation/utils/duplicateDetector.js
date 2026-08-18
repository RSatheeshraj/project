const crypto = require('crypto');

class DuplicateDetector {
  constructor() {
    this.signatures = new Set();
    this.stats = {
      candidates: 0,
      unique: 0,
      rejectedDuplicates: 0,
      rejectedDetails: []
    };
  }

  /**
   * Generates a normalized signature string from test properties
   */
  generateSignature(testCase) {
    const normalize = (str) => (str || '').toLowerCase().replace(/[^a-z0-9]/g, '');
    
    const feature = normalize(testCase.feature);
    const routeOrScreen = normalize(testCase.routeOrScreen || testCase.screen);
    const actionSeq = normalize(testCase.steps ? testCase.steps.join('') : testCase.title);
    const inputCond = normalize(JSON.stringify(testCase.testData || {}));
    const expected = normalize(testCase.expectedResult);

    const rawSignature = `${feature}|${routeOrScreen}|${actionSeq}|${inputCond}|${expected}`;
    return crypto.createHash('sha256').update(rawSignature).digest('hex');
  }

  /**
   * Evaluates a test case and registers it if unique
   * @returns {boolean} true if unique, false if duplicate
   */
  evaluate(testCase) {
    this.stats.candidates++;
    const sig = this.generateSignature(testCase);

    if (this.signatures.has(sig)) {
      this.stats.rejectedDuplicates++;
      this.stats.rejectedDetails.push({
        testId: testCase.testId,
        title: testCase.title,
        reason: 'Duplicate signature detected'
      });
      return false;
    }

    this.signatures.add(sig);
    this.stats.unique++;
    return true;
  }

  /**
   * Filters an array of candidate test cases, returning only unique scenarios
   */
  filterUnique(testCases) {
    return testCases.filter((tc) => this.evaluate(tc));
  }

  getReport() {
    return this.stats;
  }
}

module.exports = DuplicateDetector;

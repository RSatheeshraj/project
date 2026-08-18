class DuplicateDetector {
  constructor() {
    this.seenIds = new Set();
    this.seenTitles = new Set();
    this.seenSignatures = new Set();
    this.candidates = 0;
    this.unique = 0;
    this.rejectedDuplicates = 0;
    this.duplicateDetails = [];
  }

  filterUnique(scenarios) {
    const uniqueList = [];

    for (const tc of scenarios) {
      this.candidates++;
      const idKey = (tc.testId || '').trim().toUpperCase();
      const titleKey = (tc.title || '').trim().toLowerCase();
      
      // Signature checks ID, title, route/endpoint, and scenarioType
      const sigKey = `${idKey}|${titleKey}|${tc.routeOrScreen || tc.endpoint || ''}|${tc.scenarioType || ''}`;

      let isDuplicate = false;
      let reason = '';

      if (this.seenIds.has(idKey)) {
        isDuplicate = true;
        reason = `Duplicate Test ID: ${idKey}`;
      } else if (this.seenTitles.has(titleKey)) {
        isDuplicate = true;
        reason = `Duplicate Test Title: "${tc.title}"`;
      } else if (this.seenSignatures.has(sigKey)) {
        isDuplicate = true;
        reason = `Duplicate Signature: ${sigKey}`;
      }

      if (isDuplicate) {
        this.rejectedDuplicates++;
        this.duplicateDetails.push({ testId: tc.testId, title: tc.title, reason });
      } else {
        this.seenIds.add(idKey);
        this.seenTitles.add(titleKey);
        this.seenSignatures.add(sigKey);
        this.unique++;
        uniqueList.push(tc);
      }
    }

    return uniqueList;
  }

  getReport() {
    return {
      candidates: this.candidates,
      unique: this.unique,
      rejectedDuplicates: this.rejectedDuplicates,
      duplicateDetails: this.duplicateDetails
    };
  }
}

module.exports = DuplicateDetector;

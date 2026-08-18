const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

async function generateExcelReport(testResults, summaryMetrics, outputPath) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'PoultryGuardLite Mobile QA System';
  workbook.created = new Date();

  const headerFill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1F4E78' } };
  const headerFont = { color: { argb: 'FFFFFFFF' }, bold: true };
  const passFill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } };
  const failFill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFCE4D6' } };
  const skipFill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF2F2F2' } };

  const columns = [
    { header: 'Test ID', key: 'testId', width: 15 },
    { header: 'Title', key: 'title', width: 35 },
    { header: 'Category', key: 'category', width: 18 },
    { header: 'Feature', key: 'feature', width: 18 },
    { header: 'Route / Screen', key: 'routeOrScreen', width: 22 },
    { header: 'Preconditions', key: 'preconditions', width: 25 },
    { header: 'Test Data', key: 'testDataStr', width: 25 },
    { header: 'Steps', key: 'stepsStr', width: 35 },
    { header: 'Expected Result', key: 'expectedResult', width: 30 },
    { header: 'Actual Result', key: 'actualResult', width: 30 },
    { header: 'Status', key: 'status', width: 12 },
    { header: 'Error Details', key: 'error', width: 30 },
    { header: 'Duration (ms)', key: 'duration', width: 15 },
    { header: 'Timestamp', key: 'timestamp', width: 22 },
    { header: 'Browser / Device', key: 'environment', width: 20 },
    { header: 'Screenshot Path', key: 'screenshotPath', width: 30 }
  ];

  const addRowsToSheet = (sheet, data) => {
    sheet.columns = columns;
    sheet.getRow(1).fill = headerFill;
    sheet.getRow(1).font = headerFont;

    data.forEach((tc) => {
      const row = sheet.addRow({
        ...tc,
        testDataStr: typeof tc.testData === 'object' ? JSON.stringify(tc.testData) : tc.testData,
        stepsStr: Array.isArray(tc.steps) ? tc.steps.join(' | ') : tc.steps
      });

      if (tc.status === 'PASS') row.getCell('status').fill = passFill;
      else if (tc.status === 'FAIL') row.getCell('status').fill = failFill;
      else if (tc.status === 'SKIPPED' || tc.status === 'BLOCKED') row.getCell('status').fill = skipFill;
    });
  };

  const sheetInventory = workbook.addWorksheet('Test Inventory');
  addRowsToSheet(sheetInventory, testResults);

  const sheetExecuted = workbook.addWorksheet('Executed');
  addRowsToSheet(sheetExecuted, testResults.filter(t => t.status !== 'UNEXECUTED'));

  const sheetPassed = workbook.addWorksheet('Passed');
  addRowsToSheet(sheetPassed, testResults.filter(t => t.status === 'PASS'));

  const sheetFailed = workbook.addWorksheet('Failed');
  addRowsToSheet(sheetFailed, testResults.filter(t => t.status === 'FAIL'));

  const sheetSkipped = workbook.addWorksheet('Skipped');
  addRowsToSheet(sheetSkipped, testResults.filter(t => t.status === 'SKIPPED'));

  const sheetBlocked = workbook.addWorksheet('Blocked');
  addRowsToSheet(sheetBlocked, testResults.filter(t => t.status === 'BLOCKED'));

  const sheetMetrics = workbook.addWorksheet('Metrics');
  sheetMetrics.columns = [
    { header: 'Metric Name', key: 'metric', width: 35 },
    { header: 'Value', key: 'value', width: 25 }
  ];
  sheetMetrics.getRow(1).fill = headerFill;
  sheetMetrics.getRow(1).font = headerFont;

  Object.entries(summaryMetrics).forEach(([key, val]) => {
    sheetMetrics.addRow({ metric: key, value: val });
  });

  const sheetEnv = workbook.addWorksheet('Environment');
  sheetEnv.columns = [
    { header: 'Parameter', key: 'param', width: 25 },
    { header: 'Details', key: 'details', width: 45 }
  ];
  sheetEnv.getRow(1).fill = headerFill;
  sheetEnv.getRow(1).font = headerFont;

  sheetEnv.addRow({ param: 'Execution Date', details: new Date().toISOString() });
  sheetEnv.addRow({ param: 'Platform', details: process.platform });
  sheetEnv.addRow({ param: 'Node Version', details: process.version });
  sheetEnv.addRow({ param: 'Target App', details: 'PoultryGuardLite Mobile' });

  const dir = path.dirname(outputPath);
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }

  await workbook.xlsx.writeFile(outputPath);
  console.log(`[ExcelReporter] Mobile Excel report successfully generated at: ${outputPath}`);
}

module.exports = { generateExcelReport };

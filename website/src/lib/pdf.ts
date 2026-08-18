import jsPDF from 'jspdf';
import { Branding } from '@/config/branding';
import autoTable from 'jspdf-autotable';
import { formatDate } from '@/lib/utils';
import { formatCurrency } from '@/lib/currency';
import type { Farm, Batch, WeeklyEntry, ScanHistory, Sale, UserProfile } from '@/types/models';
import { calculateTotalRevenue, calculateTotalBirdsSold, calculateProductionWeek } from '@/lib/calculations';
import { RobotoRegular, RobotoBold } from '@/lib/fonts';

/**
 * Creates a standard jsPDF document with the company branding if available, or PoultryGuardLite branding as fallback.
 * @param title The title of the report.
 * @param userProfile The user profile containing company information.
 * @param orientation 'portrait' or 'landscape'
 * @returns A jsPDF instance and the next available Y coordinate for content.
 */
export async function createBrandedPDF(
  title: string, 
  userProfile: UserProfile | null,
  orientation: 'portrait' | 'landscape' = 'portrait', 
  version: string = '1.2'
) {
  const doc = new jsPDF({ orientation });
  const pageWidth = doc.internal.pageSize.getWidth();
  const pageHeight = doc.internal.pageSize.getHeight();

  doc.addFileToVFS('Roboto-Regular.ttf', RobotoRegular);
  doc.addFont('Roboto-Regular.ttf', 'Roboto', 'normal');
  doc.addFileToVFS('Roboto-Bold.ttf', RobotoBold);
  doc.addFont('Roboto-Bold.ttf', 'Roboto', 'bold');
  doc.setFont('Roboto', 'normal');
  
  const logoUrl = Branding.reports.headerLogo;
  let logoData: string | null = null;
  const startX = 14;
  let currentHeaderY = 16;
  
  try {
    logoData = await fetchImageAsBase64(logoUrl);
    if (logoData) {
      const props = doc.getImageProperties(logoData);
      const ratio = props.width / props.height;
      
      let logoHeight = 50;
      let logoWidth = logoHeight * ratio;
      
      if (logoWidth > 50) {
        logoWidth = 50;
        logoHeight = logoWidth / ratio;
      }
      
      doc.addImage(logoData, 'PNG', startX, 10, logoWidth, logoHeight, '', 'FAST');
      
      // Add spacing below logo for vertical alignment
      currentHeaderY = 10 + logoHeight + 12;
    }
  } catch {
    // Silent fallback
  }

  // Header Text
  doc.setFontSize(16);
  doc.setTextColor('#F4A900'); 
  doc.text(Branding.appName, startX, currentHeaderY);
  
  doc.setFontSize(10);
  doc.setTextColor(100);
  
  currentHeaderY += 6;
  doc.text(Branding.tagline, startX, currentHeaderY);

  // Tagline / Date on the right
  const now = new Date();
  doc.text(`Generated: ${now.toLocaleDateString()} ${now.toLocaleTimeString()}`, pageWidth - 14, 20, { align: 'right' });
  doc.text(`Report Version: ${version}`, pageWidth - 14, 25, { align: 'right' });

  // Divider
  const headerBottomY = Math.max(52, currentHeaderY + 8);
  doc.setDrawColor(200);
  doc.line(14, headerBottomY, pageWidth - 14, headerBottomY);

  // Title
  doc.setFontSize(18);
  doc.setTextColor(20);
  doc.text(title, 14, headerBottomY + 10);

  // Footer function to add on every page
  const addFooter = () => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const pages = (doc as any).getNumberOfPages();
    for (let i = 1; i <= pages; i++) {
      doc.setPage(i);
      doc.setDrawColor(200);
      doc.line(14, pageHeight - 16, pageWidth - 14, pageHeight - 16);
      
      doc.setFontSize(10);
      doc.setTextColor('#F4A900');
      doc.text(Branding.appName, 14, pageHeight - 8);
      
      doc.setFontSize(8);
      doc.setTextColor(120);
      doc.text(`Powered by PoultryGuardLite | Version ${version}`, 60, pageHeight - 8);
      doc.text(Branding.copyright, 14, pageHeight - 4);

      doc.text(`Generated On: ${now.toLocaleDateString()}`, pageWidth - 14, pageHeight - 10, { align: 'right' });
      doc.text(`Page ${i} of ${pages}`, pageWidth - 14, pageHeight - 6, { align: 'right' });
    }
  };

  return { doc, startY: headerBottomY + 18, addFooter, pageWidth, pageHeight };
}

/** Helper to fetch image and convert to base64 for jsPDF */
async function fetchImageAsBase64(url: string): Promise<string> {
  const response = await fetch(url);
  const blob = await response.blob();
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(reader.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}

export async function generateWeeklyReportPdf(
  farm: Farm,
  batch: Batch,
  entries: WeeklyEntry[],
  scans: ScanHistory[],
  userProfile: UserProfile | null
) {
  const { doc, startY, addFooter, pageWidth } = await createBrandedPDF(`Weekly Report: ${batch.batchName}`, userProfile, 'portrait');

  doc.setFontSize(12);
  doc.setTextColor(50);
  
  let currentY = startY;
  const maxWidth = pageWidth - 28;
  const lineHeight = 6;
  
  const farmLines = doc.splitTextToSize(`Farm: ${farm.name}`, maxWidth);
  doc.text(farmLines, 14, currentY);
  currentY += (farmLines.length * lineHeight) + 2;
  
  const batchLines = doc.splitTextToSize(`Batch: ${batch.batchName}`, maxWidth);
  doc.text(batchLines, 14, currentY);
  currentY += (batchLines.length * lineHeight) + 2;
  
  doc.text(`Initial Birds: ${batch.totalBirds}`, 14, currentY);
  currentY += lineHeight + 10;

  // Entries Table
  if (entries.length > 0) {
    doc.setFontSize(14);
    doc.setTextColor(20);
    doc.text('Weekly Entries', 14, currentY);
    
    const tableData = entries.map((e) => [
      calculateProductionWeek(batch.arrivalDate, e.entryDate),
      formatDate(e.entryDate || new Date()),
      e.mortalityCount.toString(),
      e.feedConsumedKg.toString(),
      e.waterConsumedLitres.toString(),
      e.averageWeightKg.toString()
    ]);

    autoTable(doc, {
      startY: currentY + 6,
      head: [['Week', 'Date', 'Mortality', 'Feed (kg)', 'Water (L)', 'Avg Weight (g)']],
      body: tableData,
      theme: 'grid',
      headStyles: { fillColor: '#F4A900', textColor: '#ffffff' },
      styles: { fontSize: 10, font: 'Roboto' },
    });

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    currentY = (doc as any).lastAutoTable.finalY + 15;
  }

  // AI Scans Table
  if (scans.length > 0) {
    if (currentY > 250) {
      doc.addPage();
      currentY = 20;
    }

    doc.setFontSize(14);
    doc.setTextColor(20);
    doc.text('AI Scans History', 14, currentY);

    const scanData = scans.map(s => [
      formatDate(s.createdAt),
      s.result.diseaseName,
      s.result.confidence,
      s.result.severity
    ]);

    autoTable(doc, {
      startY: currentY + 6,
      head: [['Date', 'Disease Identified', 'Confidence', 'Severity']],
      body: scanData,
      theme: 'grid',
      headStyles: { fillColor: '#F4A900', textColor: '#ffffff' },
      styles: { fontSize: 10, font: 'Roboto' },
      didParseCell: function(data) {
        if (data.section === 'body' && data.column.index === 3) {
          const severity = data.cell.raw;
          if (severity === 'High' || severity === 'Critical') {
            data.cell.styles.textColor = '#ef4444';
            data.cell.styles.fontStyle = 'bold';
          }
        }
      }
    });
  }

  addFooter();
  return doc;
}

export async function generateSalesReportPdf(
  farm: Farm,
  sales: Sale[],
  batches: Batch[],
  userProfile: UserProfile | null
) {
  const { doc, startY, addFooter, pageWidth, pageHeight } = await createBrandedPDF(`SALES REPORT`, userProfile, 'landscape', '1.2');

  // FARM INFORMATION
  doc.setFontSize(12);
  doc.setTextColor(20);
  doc.setFont('Roboto', 'bold');
  doc.text('FARM INFORMATION', 14, startY);
  
  doc.setFontSize(10);
  doc.setTextColor(50);
  doc.setFont('Roboto', 'normal');
  
  const leftColX = 14;
  const rightColX = pageWidth / 2;
  const colMaxWidth = (pageWidth / 2) - 28;
  const lineHeight = 5;
  
  let leftY = startY + 6;
  const farmLines = doc.splitTextToSize(`Farm Name: ${farm.name}`, colMaxWidth);
  doc.text(farmLines, leftColX, leftY);
  leftY += farmLines.length * lineHeight + 1;
  
  const ownerLines = doc.splitTextToSize(`Owner Name: ${farm.ownerName}`, colMaxWidth);
  doc.text(ownerLines, leftColX, leftY);
  leftY += ownerLines.length * lineHeight;
  
  let rightY = startY + 6;
  const locationLines = doc.splitTextToSize(`Location: ${farm.address || 'N/A'}`, colMaxWidth);
  doc.text(locationLines, rightColX, rightY);
  rightY += locationLines.length * lineHeight + 1;
  
  const activeBatches = batches.filter(b => b.status === 'Active').length;
  doc.text(`Active Batches: ${activeBatches}`, rightColX, rightY);
  rightY += lineHeight;
  
  const sectionBottomY = Math.max(leftY, rightY);
  
  doc.setDrawColor(220);
  doc.line(14, sectionBottomY + 4, pageWidth - 14, sectionBottomY + 4);

  // SUMMARY CARDS
  const totalRevenue = calculateTotalRevenue(sales);
  const totalBirdsSold = calculateTotalBirdsSold(sales);
  const totalWeight = sales.reduce((acc, sale) => acc + (sale.totalWeight || 0), 0);
  const averagePricePerKg = totalWeight > 0 ? totalRevenue / totalWeight : 0;
  const totalProfit = sales.reduce((acc, sale) => acc + (sale.estimatedProfit || 0), 0);
  const numberOfSales = sales.length;

  let currentY = sectionBottomY + 12;
  doc.setFontSize(12);
  doc.setTextColor(20);
  doc.setFont('Roboto', 'bold');
  doc.text('SUMMARY', 14, currentY);
  
  doc.setFontSize(10);
  doc.setTextColor(50);
  doc.setFont('Roboto', 'normal');
  const cw = (pageWidth - 28) / 5; // column width
  doc.text(`Total Revenue\n${formatCurrency(totalRevenue)}`, 14, currentY + 6);
  doc.text(`Birds Sold\n${totalBirdsSold.toLocaleString()}`, 14 + cw, currentY + 6);
  doc.text(`Avg Price/Kg\n${formatCurrency(averagePricePerKg)}`, 14 + cw * 2, currentY + 6);
  doc.text(`Est. Profit\n${formatCurrency(totalProfit)}`, 14 + cw * 3, currentY + 6);
  doc.text(`Number of Sales\n${numberOfSales}`, 14 + cw * 4, currentY + 6);

  currentY += 18;
  doc.line(14, currentY, pageWidth - 14, currentY);
  currentY += 8;

  const batchMap = new Map(batches.map(b => [b.id, b.batchName]));

  if (sales.length > 0) {
    // SALES TABLE
    doc.setFontSize(12);
    doc.setTextColor(20);
    doc.setFont('Roboto', 'bold');
    doc.text('SALES RECORDS', 14, currentY);
    doc.setFont('Roboto', 'normal');

    const tableData = sales.map(s => [
      s.saleDate ? formatDate(s.saleDate) : 'Unknown',
      batchMap.get(s.batchId) || 'Unknown Batch',
      s.buyerName,
      s.birdsSold.toString(),
      `${s.averageWeight} kg`,
      `${formatCurrency(s.pricePerKg)}`,
      `${formatCurrency(s.revenue)}`,
      'Completed',
      s.notes || '-'
    ]);

    autoTable(doc, {
      startY: currentY + 4,
      head: [['Sale Date', 'Batch', 'Buyer Name', 'Birds Sold', 'Avg Weight', 'Price/Kg', 'Total Amount', 'Status', 'Notes']],
      body: tableData,
      theme: 'grid',
      headStyles: { fillColor: '#F4A900', textColor: '#ffffff' },
      styles: { fontSize: 9, font: 'Roboto' },
    });

    // ANALYTICS SECTION
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    currentY = (doc as any).lastAutoTable.finalY + 15;

    // Check pagination for analytics
    if (currentY > pageHeight - 50) {
      doc.addPage();
      currentY = 20;
    }

    doc.setFontSize(12);
    doc.setTextColor(20);
    doc.setFont('Roboto', 'bold');
    doc.text('ANALYTICS', 14, currentY);
    
    doc.setFontSize(10);
    doc.setTextColor(50);
    doc.setFont('Roboto', 'normal');

    const highestSale = Math.max(...sales.map(s => s.revenue));
    const lowestSale = Math.min(...sales.map(s => s.revenue));
    const avgRevPerSale = numberOfSales > 0 ? totalRevenue / numberOfSales : 0;
    const avgBirdsSold = numberOfSales > 0 ? Math.round(totalBirdsSold / numberOfSales) : 0;
    
    // Most sold batch
    const batchSalesCount: Record<string, number> = {};
    sales.forEach(s => {
      batchSalesCount[s.batchId] = (batchSalesCount[s.batchId] || 0) + 1;
    });
    const mostSoldBatchId = Object.keys(batchSalesCount).reduce((a, b) => batchSalesCount[a] > batchSalesCount[b] ? a : b, '');
    const mostSoldBatchName = batchMap.get(mostSoldBatchId) || 'Unknown';

    let col1Y = currentY + 8;
    doc.text(`Highest Sale: ${formatCurrency(highestSale)}`, 14, col1Y);
    col1Y += 6;
    doc.text(`Lowest Sale: ${formatCurrency(lowestSale)}`, 14, col1Y);
    
    let col2Y = currentY + 8;
    doc.text(`Avg Revenue / Sale: ${formatCurrency(avgRevPerSale)}`, 14 + cw * 1.5, col2Y);
    col2Y += 6;
    doc.text(`Avg Birds Sold: ${avgBirdsSold}`, 14 + cw * 1.5, col2Y);
    
    let col3Y = currentY + 8;
    const batchLines = doc.splitTextToSize(`Most Sold Batch: ${mostSoldBatchName}`, cw * 1.8);
    doc.text(batchLines, 14 + cw * 3, col3Y);
    col3Y += batchLines.length * 6;
    doc.text(`Total Sales Value: ${formatCurrency(totalRevenue)}`, 14 + cw * 3, col3Y);

  } else {
    doc.setFontSize(12);
    doc.setTextColor(100);
    doc.text('No sales records found for this farm.', 14, currentY + 10);
  }

  addFooter();
  return doc;
}
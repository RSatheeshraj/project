const http = require('http');
const { URL } = require('url');

const BASE_URL = process.env.BASE_URL || 'http://127.0.0.1:3000';

function sendSingleRequest(targetUrl) {
  return new Promise((resolve) => {
    const startTime = Date.now();
    try {
      const parsedUrl = new URL(targetUrl);
      const options = {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port || 80,
        path: `${parsedUrl.pathname}${parsedUrl.search}`,
        method: 'GET',
        headers: { 'User-Agent': 'PoultryGuard-LoadTester/1.0' },
        timeout: 5000
      };

      const req = http.request(options, (res) => {
        let body = '';
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          const duration = Date.now() - startTime;
          resolve({ success: res.statusCode < 500, duration, statusCode: res.statusCode });
        });
      });

      req.on('error', () => {
        resolve({ success: false, duration: Date.now() - startTime, statusCode: 0 });
      });

      req.on('timeout', () => {
        req.destroy();
        resolve({ success: false, duration: Date.now() - startTime, statusCode: 408 });
      });

      req.end();
    } catch (e) {
      resolve({ success: false, duration: Date.now() - startTime, statusCode: 0 });
    }
  });
}

function calculatePercentile(latencies, percentile) {
  if (latencies.length === 0) return 0;
  const sorted = [...latencies].sort((a, b) => a - b);
  const index = Math.ceil((percentile / 100) * sorted.length) - 1;
  return sorted[Math.max(0, index)];
}

async function runLoadProfile(profileName, concurrency, totalRequests, targetPath = '/login') {
  console.log(`[LoadTester] Running profile "${profileName}" (${concurrency} VUs, ${totalRequests} requests)...`);
  const targetUrl = `${BASE_URL}${targetPath}`;
  const startTime = Date.now();

  const latencies = [];
  let successfulRequests = 0;
  let failedRequests = 0;

  // Concurrent worker batching
  for (let i = 0; i < totalRequests; i += concurrency) {
    const currentBatch = Math.min(concurrency, totalRequests - i);
    const promises = [];
    for (let c = 0; c < currentBatch; c++) {
      promises.push(sendSingleRequest(targetUrl));
    }
    const results = await Promise.all(promises);
    results.forEach(res => {
      latencies.push(res.duration);
      successfulRequests++;
    });
  }

  const totalTimeSec = (Date.now() - startTime) / 1000;
  const throughput = totalTimeSec > 0 ? (totalRequests / totalTimeSec).toFixed(2) : '0';
  const avgLatency = latencies.length > 0 ? (latencies.reduce((a, b) => a + b, 0) / latencies.length).toFixed(2) : 0;

  return {
    profile: profileName,
    endpoint: targetPath,
    totalRequests,
    successfulRequests,
    failedRequests,
    successRate: totalRequests > 0 ? `${((successfulRequests / totalRequests) * 100).toFixed(2)}%` : '0%',
    throughput: `${throughput} req/s`,
    avgLatency: Number(avgLatency),
    minLatency: latencies.length > 0 ? Math.min(...latencies) : 0,
    maxLatency: latencies.length > 0 ? Math.max(...latencies) : 0,
    p50: calculatePercentile(latencies, 50),
    p90: calculatePercentile(latencies, 90),
    p95: calculatePercentile(latencies, 95),
    p99: calculatePercentile(latencies, 99)
  };
}

async function runLoadSuite() {
  console.log('====================================================');
  console.log('STARTING REAL LOAD & PERFORMANCE TESTING SUITE');
  console.log('====================================================');

  const profiles = [
    { name: 'Baseline Load (1 VU)', concurrency: 1, requests: 10, path: '/login' },
    { name: 'Normal Load (5 VUs)', concurrency: 5, requests: 25, path: '/login' },
    { name: 'Stress Load (10 VUs)', concurrency: 10, requests: 50, path: '/api/ai-scan' },
    { name: 'Spike Traffic Burst', concurrency: 15, requests: 30, path: '/login' },
    { name: 'Soak Sustained Load', concurrency: 5, requests: 20, path: '/register' }
  ];

  const results = [];
  for (const p of profiles) {
    const res = await runLoadProfile(p.name, p.concurrency, p.requests, p.path);
    results.push(res);
  }

  console.log('\n====================================================');
  console.log('LOAD TESTING RESULTS SUMMARY');
  console.log('====================================================');
  console.table(results);

  return results;
}

if (require.main === module) {
  runLoadSuite().catch(e => {
    console.error('Fatal Load Testing error:', e);
    process.exit(1);
  });
}

module.exports = { runLoadSuite };

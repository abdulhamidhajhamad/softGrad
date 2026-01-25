// Test the AI Search endpoint directly
const http = require('http');

const data = JSON.stringify({
  city: "Nablus",
  guestCount: 150,
  budgetMin: 20000,
  budgetMax: 25000,
  eventType: "Wedding",
  eventDate: "2026-02-27T00:00:00.000",
  startTime: "16:00",
  endTime: "18:00",
  userTags: ["Indoor", "Venues", "Catering", "Photographers", "Car Rental & Transportation"],
  servicePriorities: [
    { name: "Venues", priority: 1, budgetPercent: 40 },
    { name: "Catering", priority: 2, budgetPercent: 30 },
    { name: "Photographers", priority: 3, budgetPercent: 15 },
    { name: "Car Rental & Transportation", priority: 4, budgetPercent: 15 }
  ],
  budgetFlexibility: 15
});

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/ai-search',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length,
    // You'll need a valid JWT token here
    'Authorization': 'Bearer YOUR_TOKEN_HERE'
  }
};

console.log('🧪 Testing AI Search endpoint...');
console.log('📤 Request:', JSON.stringify(JSON.parse(data), null, 2));

const req = http.request(options, (res) => {
  let body = '';
  
  res.on('data', (chunk) => {
    body += chunk;
  });
  
  res.on('end', () => {
    console.log('\n📥 Response Status:', res.statusCode);
    try {
      const parsed = JSON.parse(body);
      console.log('📦 Response:', JSON.stringify(parsed, null, 2));
    } catch (e) {
      console.log('📦 Response (raw):', body);
    }
  });
});

req.on('error', (e) => {
  console.error('❌ Request error:', e.message);
});

req.write(data);
req.end();

const http = require('http');

// Test chat ID that has 77 messages
const chatId = '6939dea2aa5160805a4db4fe';

const options = {
  hostname: 'localhost',
  port: 3000,
  path: `/chat/messages/${chatId}`,
  method: 'GET',
  headers: {
    'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2OTM2ODVkMjRjZmVjNzRhYTQ0NGU4NjQiLCJlbWFpbCI6InAiLCJyb2xlIjoidmVuZG9yIiwiZXhwaXJlc0luIjoiMjRoIiwiaWF0IjoxNzUxMTY3ODgwLCJleHAiOjE3NTEyNTQyODB9.YQzWNW3d2wHsPF-GBG_GCsLUo5RxPFV4Y_jT1Rk_E3M'
  }
};

const req = http.request(options, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    try {
      const json = JSON.parse(data);
      console.log('Messages count:', Array.isArray(json) ? json.length : 'Not an array');
      if (Array.isArray(json) && json.length > 0) {
        console.log('First message:', JSON.stringify(json[0], null, 2));
      } else {
        console.log('Response:', data.substring(0, 500));
      }
    } catch (e) {
      console.log('Response:', data.substring(0, 500));
    }
  });
});

req.on('error', (error) => {
  console.error('Error:', error);
});

req.end();

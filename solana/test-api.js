#!/usr/bin/env node

// Simple API test script for Web3Auth service
import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:4000';

async function testAPI() {
  console.log('🧪 Testing Web3Auth API...\n');

  try {
    // Test 1: Health check
    console.log('1. Testing health endpoint...');
    const healthResponse = await fetch(`${BASE_URL}/health`);
    const healthData = await healthResponse.json();
    console.log('✅ Health check:', healthData);
    console.log('');

    // Test 2: Root endpoint
    console.log('2. Testing root endpoint...');
    const rootResponse = await fetch(`${BASE_URL}/`);
    const rootData = await rootResponse.json();
    console.log('✅ Root endpoint:', rootData);
    console.log('');

    // Test 3: getUserId with valid address
    console.log('3. Testing getUserId with valid address...');
    const testAddress = '5oNDL3swdJJF1g9DzJiZ4ynHXgszjAEpUkxVYejchzrY';
    const userIdResponse = await fetch(`${BASE_URL}/getUserId`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ address: testAddress })
    });
    const userIdData = await userIdResponse.json();
    console.log('✅ getUserId response:', userIdData);
    console.log('');

    // Test 4: getUserId with invalid address
    console.log('4. Testing getUserId with invalid address...');
    const invalidResponse = await fetch(`${BASE_URL}/getUserId`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ address: 'invalid_address' })
    });
    const invalidData = await invalidResponse.json();
    console.log('✅ Invalid address response:', invalidData);
    console.log('');

    // Test 5: Missing parameters
    console.log('5. Testing missing parameters...');
    const missingResponse = await fetch(`${BASE_URL}/getUserId`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({})
    });
    const missingData = await missingResponse.json();
    console.log('✅ Missing parameters response:', missingData);
    console.log('');

    // Test 6: 404 endpoint
    console.log('6. Testing 404 endpoint...');
    const notFoundResponse = await fetch(`${BASE_URL}/nonexistent`);
    const notFoundData = await notFoundResponse.json();
    console.log('✅ 404 response:', notFoundData);
    console.log('');

    console.log('🎉 All tests completed successfully!');

  } catch (error) {
    console.error('❌ Test failed:', error.message);
    console.log('\n💡 Make sure the server is running on port 4000');
    console.log('   Run: npm start');
  }
}

// Run tests
testAPI();
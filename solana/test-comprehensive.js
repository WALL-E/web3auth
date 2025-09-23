#!/usr/bin/env node

// Comprehensive API test script for Web3Auth service
import fetch from 'node-fetch';

const BASE_URL = 'http://localhost:4000';

// Test data
const testCases = {
  validAddress: '5oNDL3swdJJF1g9DzJiZ4ynHXgszjAEpUkxVYejchzrY',
  invalidAddress: 'invalid_address',
  shortAddress: '123',
  emptyAddress: '',
  // Mock signature for testing (this won't pass real verification)
  mockSignature: '52VJa6DBU92aMLkm5hVwJDNqQsjzKR3AZvqsX2EdAbtZVfMkzdLcS3oAdGbWP1c29wxYuPZkUNoNm6Eg9Mc7yGJD'
};

async function makeRequest(endpoint, method = 'GET', body = null, headers = {}) {
  const options = {
    method,
    headers: {
      'Content-Type': 'application/json',
      ...headers
    }
  };
  
  if (body) {
    options.body = JSON.stringify(body);
  }
  
  const response = await fetch(`${BASE_URL}${endpoint}`, options);
  const data = await response.json();
  
  return {
    status: response.status,
    data,
    ok: response.ok
  };
}

async function testHealthEndpoint() {
  console.log('🏥 Testing Health Endpoint...');
  
  const result = await makeRequest('/health');
  console.log(`   Status: ${result.status}`);
  console.log(`   Response:`, result.data);
  
  if (result.ok && result.data.status === 'ok') {
    console.log('   ✅ Health check passed\n');
    return true;
  } else {
    console.log('   ❌ Health check failed\n');
    return false;
  }
}

async function testRootEndpoint() {
  console.log('🏠 Testing Root Endpoint...');
  
  const result = await makeRequest('/');
  console.log(`   Status: ${result.status}`);
  console.log(`   Response:`, result.data);
  
  if (result.ok && result.data.message) {
    console.log('   ✅ Root endpoint passed\n');
    return true;
  } else {
    console.log('   ❌ Root endpoint failed\n');
    return false;
  }
}

async function testGetUserIdEndpoint() {
  console.log('🆔 Testing getUserId Endpoint...');
  
  // Test 1: Valid address
  console.log('   Test 1: Valid address');
  let result = await makeRequest('/getUserId', 'POST', { address: testCases.validAddress });
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  let userId = null;
  if (result.ok && result.data.result) {
    console.log('   ✅ Valid address test passed');
    userId = result.data.result;
  } else {
    console.log('   ❌ Valid address test failed');
  }
  
  // Test 2: Invalid address
  console.log('   Test 2: Invalid address');
  result = await makeRequest('/getUserId', 'POST', { address: testCases.invalidAddress });
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (!result.ok && result.data.error) {
    console.log('   ✅ Invalid address test passed');
  } else {
    console.log('   ❌ Invalid address test failed');
  }
  
  // Test 3: Missing address
  console.log('   Test 3: Missing address');
  result = await makeRequest('/getUserId', 'POST', {});
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (!result.ok && result.data.error) {
    console.log('   ✅ Missing address test passed');
  } else {
    console.log('   ❌ Missing address test failed');
  }
  
  console.log('');
  return userId;
}

async function testGetUserTokenEndpoint(userId) {
  console.log('🎫 Testing getUserToken Endpoint...');
  
  // Test 1: Missing parameters
  console.log('   Test 1: Missing parameters');
  let result = await makeRequest('/getUserToken', 'POST', {
    address: testCases.validAddress
  });
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (!result.ok && result.data.error) {
    console.log('   ✅ Missing parameters test passed');
  } else {
    console.log('   ❌ Missing parameters test failed');
  }
  
  // Test 2: Invalid signature (expected to fail)
  console.log('   Test 2: Invalid signature');
  result = await makeRequest('/getUserToken', 'POST', {
    address: testCases.validAddress,
    signature: testCases.mockSignature,
    uid: userId
  });
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (!result.ok && result.data.error) {
    console.log('   ✅ Invalid signature test passed (expected to fail)');
  } else {
    console.log('   ❌ Invalid signature test failed');
  }
  
  console.log('');
}

async function testCheckUserTokenEndpoint() {
  console.log('🔍 Testing checkUserToken Endpoint...');
  
  // Test 1: Missing token (POST)
  console.log('   Test 1: Missing token (POST)');
  let result = await makeRequest('/checkUserToken', 'POST', {});
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (!result.ok && result.data.error) {
    console.log('   ✅ Missing token (POST) test passed');
  } else {
    console.log('   ❌ Missing token (POST) test failed');
  }
  
  // Test 2: Invalid token (POST)
  console.log('   Test 2: Invalid token (POST)');
  result = await makeRequest('/checkUserToken', 'POST', {
    token: 'invalid_token'
  });
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (!result.ok && result.data.error) {
    console.log('   ✅ Invalid token (POST) test passed');
  } else {
    console.log('   ❌ Invalid token (POST) test failed');
  }
  
  // Test 3: Missing token (GET)
  console.log('   Test 3: Missing token (GET)');
  result = await makeRequest('/checkUserToken', 'GET');
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (!result.ok && result.data.error) {
    console.log('   ✅ Missing token (GET) test passed');
  } else {
    console.log('   ❌ Missing token (GET) test failed');
  }
  
  console.log('');
}

async function test404Endpoint() {
  console.log('🚫 Testing 404 Endpoint...');
  
  const result = await makeRequest('/nonexistent');
  console.log(`   Status: ${result.status}, Response:`, result.data);
  
  if (result.status === 404 && result.data.error) {
    console.log('   ✅ 404 test passed\n');
    return true;
  } else {
    console.log('   ❌ 404 test failed\n');
    return false;
  }
}

async function testRateLimiting() {
  console.log('⏱️  Testing Rate Limiting (making 5 quick requests)...');
  
  const promises = [];
  for (let i = 0; i < 5; i++) {
    promises.push(makeRequest('/health'));
  }
  
  const results = await Promise.all(promises);
  const successCount = results.filter(r => r.ok).length;
  
  console.log(`   Successful requests: ${successCount}/5`);
  
  if (successCount >= 4) {
    console.log('   ✅ Rate limiting test passed (normal operation)\n');
    return true;
  } else {
    console.log('   ⚠️  Rate limiting may be too strict\n');
    return false;
  }
}

async function runComprehensiveTests() {
  console.log('🧪 Starting Comprehensive Web3Auth API Tests...\n');
  
  try {
    const results = [];
    
    // Run all tests
    results.push(await testHealthEndpoint());
    results.push(await testRootEndpoint());
    
    const userId = await testGetUserIdEndpoint();
    if (userId) {
      await testGetUserTokenEndpoint(userId);
    }
    
    await testCheckUserTokenEndpoint();
    results.push(await test404Endpoint());
    results.push(await testRateLimiting());
    
    // Summary
    const passedTests = results.filter(Boolean).length;
    const totalTests = results.length;
    
    console.log('📊 Test Summary:');
    console.log(`   Passed: ${passedTests}/${totalTests}`);
    console.log(`   Success Rate: ${((passedTests/totalTests) * 100).toFixed(1)}%`);
    
    if (passedTests === totalTests) {
      console.log('\n🎉 All tests passed! The API is working correctly.');
    } else {
      console.log('\n⚠️  Some tests failed. Please check the logs above.');
    }
    
  } catch (error) {
    console.error('❌ Test suite failed:', error.message);
    console.log('\n💡 Make sure the server is running on port 4000');
    console.log('   Run: npm start');
  }
}

// Run the comprehensive tests
runComprehensiveTests();
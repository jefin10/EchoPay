#!/usr/bin/env python3
"""
Test script for VoiceUPI Intent Classification API
"""

import requests
import json

# Configuration
BASE_URL = "http://localhost:5000"  # Change this to your server URL

def test_health():
    """Test health endpoint"""
    print("\n" + "="*60)
    print("Testing /health endpoint")
    print("="*60)
    
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        return response.status_code == 200
    except Exception as e:
        print(f"Error: {e}")
        return False

def test_predict(text):
    """Test predict endpoint"""
    print("\n" + "="*60)
    print(f"Testing /predict endpoint with: '{text}'")
    print("="*60)
    
    try:
        response = requests.post(
            f"{BASE_URL}/predict",
            headers={"Content-Type": "application/json"},
            json={"text": text}
        )
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"\n✓ Prediction successful!")
            print(f"  Intent: {result['predicted_intent']}")
            print(f"  Confidence: {result['confidence_percentage']}%")
            print(f"  Keywords: {json.dumps(result['keywords'], indent=4)}")
            print(f"\nFull Response:")
            print(json.dumps(result, indent=2))
        else:
            print(f"Error Response: {response.text}")
        
        return response.status_code == 200
        
    except Exception as e:
        print(f"Error: {e}")
        return False

def main():
    print("\n" + "="*60)
    print("VoiceUPI Intent Classification API Test Suite")
    print("="*60)
    print(f"Server URL: {BASE_URL}")
    
    # Test 1: Health check
    health_ok = test_health()
    
    if not health_ok:
        print("\n❌ Server health check failed!")
        print("Make sure the Flask server is running:")
        print("  python flask_server_corrected.py")
        return
    
    print("\n✓ Server is healthy!")
    
    # Test cases
    test_cases = [
        "send 1000 rs to jefin",
        "check my balance",
        "request 500 from dad",
        "transfer 2000 rupees to john",
        "what's my account balance",
        "pay 150 to mom"
    ]
    
    print("\n" + "="*60)
    print("Running Test Cases")
    print("="*60)
    
    results = []
    for test_case in test_cases:
        success = test_predict(test_case)
        results.append((test_case, success))
    
    # Summary
    print("\n" + "="*60)
    print("Test Summary")
    print("="*60)
    
    passed = sum(1 for _, success in results if success)
    total = len(results)
    
    print(f"\nPassed: {passed}/{total}")
    print("\nResults:")
    for text, success in results:
        status = "✓" if success else "❌"
        print(f"  {status} {text}")
    
    if passed == total:
        print("\n✅ All tests passed!")
    else:
        print(f"\n⚠️  {total - passed} test(s) failed")

if __name__ == "__main__":
    main()

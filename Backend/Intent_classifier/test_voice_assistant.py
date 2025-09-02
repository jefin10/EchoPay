#!/usr/bin/env python3
"""
Test script for the Enhanced Voice Assistant
Tests all workflows: transfer money, request money, check balance, and general chat
"""

import requests
import json

# Server configuration
BASE_URL = "http://localhost:5002"
TEST_USER_PHONE = "+919999999999"

def test_voice_command(text, user_phone=TEST_USER_PHONE):
    """Test the main voice command endpoint"""
    url = f"{BASE_URL}/voice_command"
    data = {
        "text": text,
        "userPhone": user_phone
    }
    
    try:
        response = requests.post(url, json=data)
        print(f"\n{'='*60}")
        print(f"🗣️  INPUT: {text}")
        print(f"📱 USER: {user_phone}")
        print(f"{'='*60}")
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ STATUS: {result.get('status', 'unknown')}")
            print(f"🎯 INTENT: {result.get('predicted_intent', 'unknown')}")
            print(f"📊 CONFIDENCE: {result.get('confidence_percentage', 0)}%")
            
            if 'entities' in result and result['entities']:
                print(f"🔍 ENTITIES: {result['entities']}")
            
            if 'assistant_message' in result:
                print(f"🤖 ASSISTANT: {result['assistant_message']}")
            
            if 'django_response' in result:
                django_resp = result['django_response']
                print(f"🔗 DJANGO: {django_resp.get('status', 'unknown')}")
                if django_resp.get('status') == 'error':
                    print(f"❌ ERROR: {django_resp.get('error', 'unknown error')}")
            
            if 'action' in result:
                print(f"⚡ ACTION: {result['action']}")
                
        else:
            print(f"❌ ERROR: {response.status_code}")
            print(f"📝 RESPONSE: {response.text}")
            
    except Exception as e:
        print(f"💥 EXCEPTION: {e}")

def test_server_health():
    """Test server health"""
    url = f"{BASE_URL}/health"
    try:
        response = requests.get(url)
        if response.status_code == 200:
            result = response.json()
            print("🏥 SERVER HEALTH:")
            print(json.dumps(result, indent=2))
            return True
        else:
            print(f"❌ Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"💥 Health check exception: {e}")
        return False

def main():
    print("🚀 ENHANCED VOICE ASSISTANT TEST SUITE")
    print("=" * 60)
    
    # Test server health first
    if not test_server_health():
        print("❌ Server is not healthy. Exiting...")
        return
    
    print("\n🔄 TESTING VOICE ASSISTANT WORKFLOWS...")
    
    # Test cases for each workflow
    test_cases = [
        # Transfer Money Workflow
        ("Send 500 rupees to 9876543210", "💰 Transfer Money"),
        ("Transfer 1000 to john@upi", "💰 Transfer Money"),
        ("Pay 250 to mom", "💰 Transfer Money"),
        ("Send money to 9123456789", "💰 Transfer Money (Missing Amount)"),
        
        # Request Money Workflow  
        ("Request 300 from 9876543210", "💸 Request Money"),
        ("Ask dad for 500 rupees", "💸 Request Money"),
        ("Collect 1000 from john@upi", "💸 Request Money"),
        ("Request money from someone", "💸 Request Money (Missing Amount)"),
        
        # Check Balance Workflow
        ("What is my balance", "💳 Check Balance"),
        ("Check my account balance", "💳 Check Balance"),
        ("How much money do I have", "💳 Check Balance"),
        ("Show balance", "💳 Check Balance"),
        
        # General/Casual Questions (Chatbot)
        ("Hello, how are you?", "💬 General Chat"),
        ("What's the weather today?", "💬 General Chat"),
        ("Tell me a joke", "💬 General Chat"),
        ("Who are you?", "💬 General Chat"),
        ("Good morning", "💬 General Chat"),
    ]
    
    for text, description in test_cases:
        print(f"\n📝 TEST: {description}")
        test_voice_command(text)
    
    print(f"\n{'='*60}")
    print("✅ TEST SUITE COMPLETED")
    print("=" * 60)

if __name__ == "__main__":
    main()

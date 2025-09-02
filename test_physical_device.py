#!/usr/bin/env python3
"""
Test script for Physical Device - Enhanced Voice Assistant
Tests connectivity and functionality for physical device using IP: 172.16.192.54
"""

import requests
import json
import time

# Server configuration for physical device
FLASK_URL = "http://172.16.192.54:5002"
DJANGO_URL = "http://172.16.192.54:8000"
TEST_USER_PHONE = "+919999999999"

def test_server_connectivity():
    """Test basic server connectivity"""
    print("🔌 Testing Server Connectivity...")
    print("=" * 50)
    
    # Test Flask server
    try:
        response = requests.get(f"{FLASK_URL}/health", timeout=5)
        if response.status_code == 200:
            result = response.json()
            print("✅ Flask Server: CONNECTED")
            print(f"   Components: {result.get('components', {})}")
        else:
            print(f"❌ Flask Server: ERROR {response.status_code}")
    except Exception as e:
        print(f"❌ Flask Server: CONNECTION FAILED - {e}")
    
    # Test Django server
    try:
        response = requests.get(f"{DJANGO_URL}/accounts/checkHasAccount/?phoneNumber={TEST_USER_PHONE}", timeout=5)
        if response.status_code in [200, 404]:  # 404 is expected if user doesn't exist
            print("✅ Django Server: CONNECTED")
        else:
            print(f"❌ Django Server: ERROR {response.status_code}")
    except Exception as e:
        print(f"❌ Django Server: CONNECTION FAILED - {e}")

def test_voice_commands():
    """Test voice command processing"""
    print("\n🎤 Testing Voice Commands...")
    print("=" * 50)
    
    test_commands = [
        ("Check my balance", "💳 Balance Check"),
        ("Send 100 rupees to 9876543210", "💰 Money Transfer"),
        ("Request 50 from 9123456789", "💸 Money Request"),
        ("Hello, how are you?", "💬 General Chat"),
        ("What's the weather?", "💬 General Chat")
    ]
    
    for command, description in test_commands:
        print(f"\n📝 Testing: {description}")
        print(f"🗣️  Command: '{command}'")
        
        try:
            response = requests.post(
                f"{FLASK_URL}/voice_command",
                json={
                    "text": command,
                    "userPhone": TEST_USER_PHONE
                },
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"✅ Status: {result.get('status')}")
                print(f"🎯 Intent: {result.get('predicted_intent')}")
                print(f"🤖 Response: {result.get('assistant_message', 'No response')[:100]}...")
                
                if 'entities' in result and result['entities']:
                    print(f"🔍 Entities: {result['entities']}")
                    
            else:
                print(f"❌ Error: {response.status_code}")
                
        except Exception as e:
            print(f"💥 Exception: {e}")
        
        time.sleep(1)  # Small delay between requests

def test_physical_device_setup():
    """Test specific physical device setup"""
    print("\n📱 Physical Device Setup Test...")
    print("=" * 50)
    print(f"📡 Flask Server IP: 172.16.192.54:5002")
    print(f"🔗 Django Server IP: 172.16.192.54:8000")
    print(f"📞 Test Phone: {TEST_USER_PHONE}")
    
    # Test network reachability
    import socket
    
    def test_port(host, port, service_name):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(3)
            result = sock.connect_ex((host, port))
            sock.close()
            if result == 0:
                print(f"✅ {service_name} Port {port}: OPEN")
                return True
            else:
                print(f"❌ {service_name} Port {port}: CLOSED")
                return False
        except Exception as e:
            print(f"❌ {service_name} Port {port}: ERROR - {e}")
            return False
    
    test_port("172.16.192.54", 5002, "Flask Server")
    test_port("172.16.192.54", 8000, "Django Server")

def main():
    print("🚀 PHYSICAL DEVICE TEST SUITE")
    print("IP Address: 172.16.192.54")
    print("=" * 60)
    
    test_physical_device_setup()
    test_server_connectivity()
    test_voice_commands()
    
    print(f"\n{'='*60}")
    print("📱 PHYSICAL DEVICE INTEGRATION GUIDE:")
    print("=" * 60)
    print("1. Make sure both servers are running:")
    print("   - Flask: python flask_server.py (Port 5002)")
    print("   - Django: python manage.py runserver 172.16.192.54:8000")
    print("")
    print("2. In Flutter app (intent_service.dart):")
    print("   - Use IP: 172.16.192.54:5002")
    print("")
    print("3. Test voice commands:")
    print("   - 'Check my balance'")
    print("   - 'Send 100 to 9876543210'")
    print("   - 'Request 50 from 9123456789'")
    print("   - 'Hello, how are you?'")
    print("=" * 60)

if __name__ == "__main__":
    main()

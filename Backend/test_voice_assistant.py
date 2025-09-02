import requests
import json

# Test the enhanced voice assistant server
BASE_URL = "http://localhost:5002"

def test_voice_command(text, user_phone="+919999999999"):
    """Test a voice command"""
    print(f"\n🗣️  Testing: '{text}'")
    print("-" * 50)
    
    try:
        response = requests.post(
            f"{BASE_URL}/voice_command",
            json={
                "text": text,
                "userPhone": user_phone
            },
            headers={"Content-Type": "application/json"}
        )
        
        if response.status_code == 200:
            result = response.json()
            print(f"✅ Status: {result.get('status')}")
            print(f"🎯 Intent: {result.get('predicted_intent')}")
            print(f"📊 Confidence: {result.get('confidence', 0) * 100:.1f}%")
            
            if result.get('entities'):
                print(f"🔍 Entities: {result.get('entities')}")
            
            if result.get('assistant_message'):
                print(f"🤖 Assistant: {result.get('assistant_message')}")
            
            if result.get('django_response'):
                django_resp = result.get('django_response')
                if django_resp.get('status') == 'success':
                    print(f"✅ Django: {django_resp.get('message', 'Success')}")
                else:
                    print(f"❌ Django Error: {django_resp.get('error')}")
            
        else:
            print(f"❌ Error: {response.status_code}")
            print(response.text)
            
    except Exception as e:
        print(f"❌ Connection Error: {e}")

def test_server_health():
    """Test server health"""
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("✅ Server is healthy!")
            return True
        else:
            print(f"❌ Server health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Cannot connect to server: {e}")
        return False

def main():
    print("🚀 Enhanced Voice Assistant Test Suite")
    print("=" * 60)
    
    # Test server health
    if not test_server_health():
        print("\n⚠️  Make sure the enhanced server is running:")
        print("   python enhanced_voice_assistant_server.py")
        return
    
    # Test cases
    test_cases = [
        # Transfer money tests
        "Send 500 rupees to John at 9876543210",
        "Transfer 1000 to dad@upi",
        "Send 250 to my friend",
        
        # Request money tests  
        "Request 500 from mom at 9876543210",
        "Ask for 1000 from john@paytm",
        "I need 250 from my brother",
        
        # Balance check tests
        "Check my balance",
        "What is my current balance",
        "How much money do I have",
        
        # Casual/general questions
        "Hello how are you",
        "What is your name",
        "Tell me a joke",
        "What's the weather like"
    ]
    
    for test_case in test_cases:
        test_voice_command(test_case)
    
    print("\n" + "=" * 60)
    print("🎉 Test suite completed!")

if __name__ == "__main__":
    main()

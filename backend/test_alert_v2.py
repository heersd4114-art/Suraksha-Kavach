import requests
import json
import uuid

# Configuration
SERVER_URL = "http://127.0.0.1:8000/api/broadcast-alert/"
USER_ID = "9twZ7Lr4ImVb6hBEUadSkRfO74u2" # Replace with a valid User ID if needed

def simulate_alert():
    print(f"Sending alert to {SERVER_URL}...")
    
    headers = {
        "Content-Type": "application/json",
        "X-User-ID": USER_ID
    }
    
    payload = {
        "type": "fire",
        "severity": "high",
        "society": "FireGuard HQ",
        "block": "A",
        "details": {
            "gas_level": 85
        }
    }
    
    try:
        response = requests.post(SERVER_URL, headers=headers, json=payload)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
    except Exception as e:
        print(f"Error sending alert: {e}")

if __name__ == "__main__":
    simulate_alert()

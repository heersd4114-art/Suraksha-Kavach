
import json
import requests
import uuid

# Configuration (Matches user env)
URL = "http://127.0.0.1:8000/api/broadcast-alert/"
USER_ID = "9twZ7Lr4ImVb6hBEUadSkRfO74u2" # User's ID from ESP32 code

def trigger_alert():
    payload = {
        "type": "fire",
        "severity": "high",
        "society": "FireGuard HQ", # Matches ESP32
        "block": "A",
        "details": {
            "gas_level": 85
        }
    }
    
    headers = {
        "Content-Type": "application/json",
        "X-User-ID": USER_ID
    }
    
    try:
        print(f"Sending POST to {URL}")
        print(f"Payload: {json.dumps(payload, indent=2)}")
        
        response = requests.post(URL, json=payload, headers=headers)
        
        print(f"Status Code: {response.status_code}")
        try:
            print(f"Response: {json.dumps(response.json(), indent=2)}")
        except:
            print(f"Response Text: {response.text}")
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    trigger_alert()

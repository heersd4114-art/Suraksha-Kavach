from django.shortcuts import render
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from .models import SensorReading

@csrf_exempt
def receive_iot_data(request):
    if request.method == 'POST':
        try:
            # Parse the JSON data from the request body
            data = json.loads(request.body)
            
            # Save to Database
            reading = SensorReading.objects.create(
                device_id=data.get('device', 'Unknown Device'),
                gas_level=data.get('gas', 0),
                fire_level=data.get('fire', 0),
                gas_detected=data.get('gas_detected', False),
                fire_detected=data.get('fire_detected', False),
                sprinkler_on=data.get('sprinkler', False),
                led_off=data.get('led_off', False)
            )

            # Print (Optional, but good for debug)
            print("----------------------")
            print(f"Saved Reading ID: {reading.id}")
            print(str(reading))
            print("----------------------")

            return JsonResponse({"status": "success", "message": "Data saved"}, status=200)
        except json.JSONDecodeError:
            return JsonResponse({"status": "error", "message": "Invalid JSON"}, status=400)
    
    return JsonResponse({"status": "error", "message": "Only POST requests allowed"}, status=405)

from django.shortcuts import render, redirect
import firebase_admin
from firebase_admin import credentials, firestore
from django.conf import settings
import os
import datetime

# Initialize Firebase
db = None
firebase_connected = False
try:
    cred_path = os.path.join(settings.BASE_DIR, 'serviceAccountKey.json')
    if os.path.exists(cred_path):
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        db = firestore.client()
        firebase_connected = True
        print("Firebase Connected Successfully")
    else:
        print("Warning: serviceAccountKey.json not found.")
except Exception as e:
    print(f"Firebase Init Error: {e}")

def get_latest_readings(request):
    """API for Flutter App to get latest status"""
    # ... existing code ...
    # Get last 1 reading (Current Status)
    latest = SensorReading.objects.last()
    
    if not latest:
        return JsonResponse({"status": "no_data"}, status=200)

    data = {
        "timestamp": latest.timestamp,
        "device_id": latest.device_id,
        "gas_level": latest.gas_level,
        "fire_level": latest.fire_level,
        "gas_detected": latest.gas_detected,
        "fire_detected": latest.fire_detected,
        "sprinkler_on": latest.sprinkler_on,
        "led_off": latest.led_off
    }
    return JsonResponse(data, status=200)

@csrf_exempt
def manage_alerts(request):
    alerts = []
    
    if request.method == 'POST':
        action = request.POST.get('action')
        
        if action == 'create':
            title = request.POST.get('title')
            message = request.POST.get('message')
            role = request.POST.get('role')
            severity = request.POST.get('severity')
            
            new_alert = {
                'title': title,
                'message': message,
                'role': role,
                'severity': severity,
                'timestamp': datetime.datetime.now().isoformat(),
                'active': True
            }
            
            if db:
                db.collection('alerts').add(new_alert)
            else:
                print("Firebase not connected. Alert not saved to Cloud.")
                
        elif action == 'delete':
            doc_id = request.POST.get('doc_id')
            if db and doc_id:
                db.collection('alerts').document(doc_id).delete()
        
        return redirect('/alerts')

    # Fetch Alerts
    if db:
        try:
            docs = db.collection('alerts').order_by('timestamp', direction=firestore.Query.DESCENDING).stream()
            for doc in docs:
                data = doc.to_dict()
                data['id'] = doc.id
                alerts.append(data)
        except Exception as e:
            print(f"Error fetching alerts: {e}")
            
    return render(request, 'iot_server/alerts.html', {
        'alerts': alerts,
        'firebase_connected': firebase_connected
    })

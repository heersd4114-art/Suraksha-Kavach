from django.test import TestCase, Client
from .models import SensorReading

class IoTViewTests(TestCase):
    def test_receive_iot_data(self):
        client = Client()
        data = {
            "device": "test_device",
            "gas": 1500,
            "fire": 800,
            "gas_detected": False,
            "fire_detected": True,
            "sprinkler": True,
            "led_off": True
        }
        response = client.post(
            '/iot',
            data=data,
            content_type='application/json'
        )
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "success", "message": "Data saved"})
        
        # Verify it was saved to DB
        self.assertEqual(SensorReading.objects.count(), 1)
        reading = SensorReading.objects.first()
        self.assertEqual(reading.device_id, "test_device")
        self.assertEqual(reading.gas_level, 1500)

    def test_get_latest_readings(self):
        # Create a dummy reading
        SensorReading.objects.create(
            device_id="test_read",
            gas_level=123,
            fire_level=456
        )
        
        client = Client()
        response = client.get('/api/latest')
        self.assertEqual(response.status_code, 200)
        
        data = response.json()
        self.assertEqual(data['gas_level'], 123)
        self.assertEqual(data['fire_level'], 456)

    def test_receive_iot_data_method_not_allowed(self):
        client = Client()
        response = client.get('/iot')
        self.assertEqual(response.status_code, 405)

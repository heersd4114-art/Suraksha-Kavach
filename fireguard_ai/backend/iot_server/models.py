from django.db import models
from django.contrib.auth.models import User

class SensorReading(models.Model):
    timestamp = models.DateTimeField(auto_now_add=True)
    device_id = models.CharField(max_length=100)
    gas_level = models.IntegerField()
    fire_level = models.IntegerField()
    gas_detected = models.BooleanField(default=False)
    fire_detected = models.BooleanField(default=False)
    sprinkler_on = models.BooleanField(default=False)
    led_off = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.device_id} at {self.timestamp}: Fire={self.fire_detected}, Gas={self.gas_detected}"

class Profile(models.Model):
    DESIGNATION_CHOICES = [
        ('OWNER', 'Owner'),
        ('DEPT_HEAD', 'Departmental Head'),
        ('MANAGER', 'Manager'),
        ('EMPLOYEE', 'Employee'),
    ]
    
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    designation = models.CharField(max_length=20, choices=DESIGNATION_CHOICES, default='EMPLOYEE')

    def __str__(self):
        return f"{self.user.username} - {self.get_designation_display()}"

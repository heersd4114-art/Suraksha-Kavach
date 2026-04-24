# api/sync.py

from .firebase import db 
from .models import Sensor    



def listen_sensors():

    def on_snapshot(col_snapshot, changes, read_time):

        for change in changes:

            data = change.document.to_dict()
            doc_id = change.document.id

            Sensor.objects.update_or_create(
                device_id=doc_id,
                defaults={
                    "location": data.get("location"),
                    "status": data.get("status")
                }
            )

    db.collection("sensors").on_snapshot(on_snapshot)

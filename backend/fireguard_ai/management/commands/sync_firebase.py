from django.core.management.base import BaseCommand
from fireguard_ai.sync_firebase import sync_all

class Command(BaseCommand):
    help = 'Syncs data from Firebase Firestore to local SQL database'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting sync...'))
        try:
            sync_all()
            self.stdout.write(self.style.SUCCESS('Successfully synced all data.'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Sync failed: {e}'))

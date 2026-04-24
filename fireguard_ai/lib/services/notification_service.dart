import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> init() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // 2. Get and Upload Token
      await _uploadToken();
      
      // 3. Listen for Token Refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToDatabase(newToken);
      });
      
    } else {
      debugPrint('User declined or has not accepted permission');
    }
  }

  Future<void> _uploadToken() async {
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcm_token': token,
        'token_updated_at': FieldValue.serverTimestamp(),
      });
      debugPrint("FCM Token Updated: $token");
    } catch (e) {
      debugPrint("Error saving FCM token: $e");
    }
  }
}

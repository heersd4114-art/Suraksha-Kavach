import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../../main.dart'; 
import '../../pages/alert_notifications_screen.dart';

// Top-level plugin instance
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Background Handler (Must be top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("🚨 BACKGROUND MSG: ${message.messageId}");
  
  // Initialize for background isolation
  await Firebase.initializeApp(); 
  
  // Define Channel
  final AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', 
    'High Importance Notifications', 
    description: 'This channel is used for important notifications.', 
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('alarm'),
    enableVibration: true,
    // Massive vibration pattern: [delay, vibrate, pause, vibrate, pause, vibrate...]
    vibrationPattern: Int64List.fromList([0, 1000, 500, 2000, 500, 3000, 500, 5000]),
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  // Show High Priority Notification
  String title = message.notification?.title ?? message.data['title'] ?? 'Emergency Alert';
  String body = message.notification?.body ?? message.data['body'] ?? 'Critical incident reported';
  
  // v20+: Use named arguments for show()
  await flutterLocalNotificationsPlugin.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: '@mipmap/launcher_icon', 
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true, 
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: const RawResourceAndroidNotificationSound('alarm'),
          enableVibration: true,
          // Massive vibration pattern to match channel
          vibrationPattern: Int64List.fromList([0, 1000, 500, 2000, 500, 3000, 500, 5000]),
          // CRITICAL: Insistent flag makes the sound loop until cancelled/acknowledged
          additionalFlags: Int32List.fromList(<int>[4]), // 4 is FLAG_INSISTENT
          
          // PERSISTENT: Cannot be swiped away, must be handled by app
          ongoing: true,
          autoCancel: false,
        ),
      ),
      payload: message.data['incident_id'],
    );

  // START REPEATED NOTIFICATIONS
  await NotificationService().scheduleRepeatedNotifications(message);
}

class NotificationService {
  // Singleton Pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Store pending alert ID for splash screen redirection
  String? pendingAlertId;

  /// Initialize Notifications
  Future<void> init() async {
    // 0. Initialize Timezone for Scheduled Notifications
    tz.initializeTimeZones();
    // Use local timezone or fallback to UTC
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      debugPrint("⚠️ Could not get local timezone, using UTC: $e");
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    // 1. Initialize Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
        
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // v20+: Use named arguments for initialize()
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 LOCAL NOTIFICATION TAPPED: ${response.payload}');
        if (response.payload != null) {
          _navigateToAlertScreen(response.payload);
        }
      },
    );
    
    // Check if app was launched by notification
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    
    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final payload = notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        pendingAlertId = payload;
        debugPrint("🚀 App launched from notification with ID: $payload");
      }
    }

    // 1. Request Permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    
    // Create Channel for Foreground/Headless
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', 
      'High Importance Notifications', 
      description: 'This channel is used for important notifications.', 
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 2000, 500, 3000, 500, 5000]),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    // Request Exact Alarms Permission (Android 12+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    // CRITICAL: Allow notifications to show even when app is in foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, 
      badge: true, 
      sound: true
    );

    debugPrint('🔔 Permission Status: ${settings.authorizationStatus}');

    // 2. Setup Listeners
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('🔔 FOREGROUND MSG: ${message.notification?.title}');
      
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // Strategy: Use local notification to ensure high priority/alarm sound works
      // even in foreground if needed.
      
      final alertId = message.data['incident_id'];
      
      // Schedule repeated notifications
      if (message.data['title']?.toString().toUpperCase().contains('EMERGENCY') ?? false) {
         scheduleRepeatedNotifications(message);
      }

      _navigateToAlertScreen(alertId);
    });

    // Background Tap Handler (FCM native)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 NOTIFICATION TAPPED (Background FCM): ${message.notification?.title}');
      final alertId = message.data['incident_id'];
      
      // Schedule repeated notifications
      if (message.data['title']?.toString().toUpperCase().contains('EMERGENCY') ?? false) {
         scheduleRepeatedNotifications(message);
      }
      
      _navigateToAlertScreen(alertId);
    });

    // Terminated State Tap Handler (FCM native)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('🔔 NOTIFICATION TAPPED (Terminated FCM): ${message.notification?.title}');
        final alertId = message.data['incident_id'];
        _navigateToAlertScreen(alertId);
      }
    });

    // 3. Get & Save Token
    await _syncToken();

    // 4. Listen for Token Refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(newToken);
    });
    
    // 5. Listen for Auth Changes (Sync token on login)
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        debugPrint("👤 User logged in: ${user.uid}, syncing token...");
        _syncToken();
      }
    });

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
       debugPrint("⚠️ Notifications denied. User may need to enable them in Settings.");
    }
  }

  /// Sync Token Logic
  Future<void> _syncToken() async {
    String? token;
    if (kIsWeb) {
      try {
        token = await _fcm.getToken(
          vapidKey: "BJNdSdtEyE3Kxd42biywwQ1wCfDFkj64fCnqzN3DxYFjnq79WBcgVw-xwY-J_CrsjzZq9BsPrImsXXUtLGOW6jc" 
        );
      } catch (e) {
        debugPrint("❌ Web Token Error: $e");
      }
    } else {
      token = await _fcm.getToken();
    }

    if (token != null) {
      debugPrint("🔥 FCM TOKEN: $token");
      await _saveTokenToFirestore(token);
    }
  }

  /// Save Token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    User? user = _auth.currentUser;

    if (user == null) {
      debugPrint("⚠️ No logged-in user to save token.");
      return;
    }

    try {
      await _db.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      }, SetOptions(merge: true));

      debugPrint("✅ Token synced to Firestore for ${user.uid}");
    } catch (e) {
      debugPrint("❌ Failed to save token: $e");
    }
  }

  /// Schedule Repeated Notifications (Every 5 seconds for 5 minutes)
  /// REFACTORED for latest flutter_local_notifications API
  /// Removed deprecated UILocalNotificationDateInterpretation
  Future<void> scheduleRepeatedNotifications(RemoteMessage message) async {
    const int totalNotifications = 60; // 5 seconds * 60 = 300 seconds (5 mins)
    const int intervalSeconds = 5;

    // Define Channel & Details (Same as immediate)
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      icon: '@mipmap/launcher_icon',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      sound: const RawResourceAndroidNotificationSound('alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 2000, 500, 3000, 500, 5000]), 
      additionalFlags: Int32List.fromList(<int>[4]), // Insistent
      ongoing: true,
      autoCancel: false,
    );

    final NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final String title = message.notification?.title ?? message.data['title'] ?? 'Emergency Alert';
    final String body = message.notification?.body ?? message.data['body'] ?? 'Critical incident reported';
    final String? payload = message.data['incident_id'];
    
    // Base ID for original notification is usually message.hashCode
    // Ensure we don't start from 0 if hashCode is weird
    final int baseId = (message.hashCode).abs();

    debugPrint("🕒 Scheduling $totalNotifications backup notifications starting from ID: $baseId");

    // Schedule loop
    for (int i = 1; i <= totalNotifications; i++) {
      // Create a specific TImezone aware date
      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: i * intervalSeconds));
      final int scheduledId = baseId + i; 

      try {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id: scheduledId,
          title: title,
          body: "$body (Repeat $i)",
          scheduledDate: scheduledTime,
          notificationDetails: platformChannelSpecifics,
          // Android 12+ requires this mode + permission
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          // uiLocalNotificationDateInterpretation: REMOVED (Not in v20 API for this call?)
          payload: payload,
        );
        // debugPrint("⏰ Scheduled alarm #$i at $scheduledTime (ID: $scheduledId)");
      } catch (e) {
        // Fallback or ignore
        // debugPrint("❌ Failed to schedule notification #$i: $e");
      }
    }
  }

  /// Cancel specific notification (Stops sound/vibration)
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
    debugPrint("🛑 Notification $id cancelled (Alarm Stopped)");
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    debugPrint("🛑 All notifications cancelled");
  }

  /// Redirect to Alert Screen
  void _navigateToAlertScreen([String? alertId]) {
    // This assumes navigatorKey is available globally from main.dart
    if (navigatorKey.currentState != null) {
      // Clean navigation stack or just push? 
      // For alarms, typically we want to see it immediately.
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (context) => NeighborAlertScreen(alertId: alertId)),
      );
    } else {
      debugPrint("⚠️ Navigator Key is null, cannot redirect.");
    }
  }
}

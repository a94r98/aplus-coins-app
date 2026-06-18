import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../api/api_service.dart';

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final ApiService _apiService = ApiService();

  static Future<void> initialize() async {
    try {
      // 1. Request user permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted push notifications permission.');
        
        // 2. Fetch the FCM device token
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('FCM Token: $token');
          await _updateTokenOnServer(token);
        }

        // Token refresh listener
        _messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM Token Refreshed: $newToken');
          await _updateTokenOnServer(newToken);
        });

        // 3. Listen for foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint('Foreground Push Message Received: ${message.notification?.title}');
        });

        // 4. Listen for tapping notifications when app is opened from background/terminated state
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint('Push Notification clicked: ${message.data}');
        });
      } else {
        debugPrint('User declined or has not accepted push notifications permission.');
      }
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
    }
  }

  static Future<void> _updateTokenOnServer(String token) async {
    try {
      // Send fcm_token update to backend PUT /auth/profile
      final res = await _apiService.put(
        '/auth/profile',
        body: {'fcm_token': token},
      );
      if (res['status'] == 'success') {
        debugPrint('FCM token successfully synchronized with server.');
      } else {
        debugPrint('FCM token synchronization failed: ${res['message']}');
      }
    } catch (e) {
      debugPrint('Error sending FCM token to server: $e');
    }
  }
}

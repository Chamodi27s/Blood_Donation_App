import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _firebaseMessaging.subscribeToTopic('all_donors');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(settings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for urgent blood requests.',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Blood Request',
      message.notification?.body ?? 'A new blood request is available.',
      details,
    );
  }

  Future<void> sendNotificationToAll(
    String bloodGroup,
    String hospital,
  ) async {
    try {
      const String serverKey = 'YOUR_SERVER_KEY_HERE';

      final Uri url = Uri.parse('https://fcm.googleapis.com/fcm/send');

      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      };

      final Map<String, dynamic> body = {
        "to": "/topics/all_donors",
        "notification": {
          "title": "URGENT: $bloodGroup Blood Needed!",
          "body": "A patient at $hospital needs your help immediately.",
          "sound": "default",
        },
        "data": {
          "bloodGroup": bloodGroup,
          "hospital": hospital,
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
        }
      };

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        print("Notification response code: ${response.statusCode}");
        print("Notification response body: ${response.body}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error sending notification: $e");
      }
    }
  }
}
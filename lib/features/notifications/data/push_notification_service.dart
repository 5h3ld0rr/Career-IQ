import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:careeriq/features/interview/data/interview_model.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final Function(String? payload)? onNotificationClick;

  PushNotificationService({this.onNotificationClick});

  Future<void> initialize() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (onNotificationClick != null) {
          onNotificationClick!(response.payload);
        }
      },
    );

    tz.initializeTimeZones();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked!');
      if (onNotificationClick != null && message.data.containsKey('route')) {
        onNotificationClick!(message.data['route']);
      }
    });
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? route,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: platformDetails,
      payload: route,
    );
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    await showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      route: message.data['route'],
    );
  }

  Future<void> scheduleInterviewPrep(Interview interview) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'interview_prep_channel',
          'Interview Prep Notifications',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    final int notificationId = int.tryParse(interview.id) ?? interview.hashCode;
    final tz.TZDateTime tzScheduledDate = tz.TZDateTime.from(
      interview.scheduledAt,
      tz.local,
    ).subtract(const Duration(minutes: 30));

    if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      return;
    }

    await _localNotifications.zonedSchedule(
      id: notificationId,
      title: 'Interview Prep: ${interview.companyName}',
      body:
          'Your interview for ${interview.jobTitle} is in 30 minutes! Prepare with Career-IQ.',
      scheduledDate: tzScheduledDate,
      notificationDetails: platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '/tracker',
    );
  }

  Future<void> cancelInterviewPrep(int id) async {
    await _localNotifications.cancel(id: id);
  }

  Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  Future<void> simulateNotification(
    String title,
    String body,
    String type,
    String userId, {
    String? route,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'route': route,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateToken(String userId) async {
    final token = await getToken();
    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint("FCM Token updated for user $userId: $token");
    }
  }
}

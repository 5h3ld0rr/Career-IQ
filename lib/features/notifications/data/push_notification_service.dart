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

  Future<void> _showLocalNotification(RemoteMessage message) async {
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
      id: message.hashCode,
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body,
      notificationDetails: platformDetails,
      payload: message.data['route'],
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
    String userId,
  ) async {
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
      id: 0,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
          'title': title,
          'body': body,
          'type': type,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }
}

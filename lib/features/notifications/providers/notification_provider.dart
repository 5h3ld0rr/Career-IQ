import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:careeriq/features/notifications/data/notification_model.dart';
import 'package:careeriq/features/notifications/data/push_notification_service.dart';

class NotificationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  PushNotificationService? _pushNotificationService;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _userId;
  bool _isFirstLoad = true;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  PushNotificationService? get pushService => _pushNotificationService;

  void initializeService(Function(String?) onNotificationClick) {
    if (_pushNotificationService == null) {
      _pushNotificationService = PushNotificationService(
        onNotificationClick: onNotificationClick,
      );
      _pushNotificationService!.initialize();
    }
  }

  void loadUserNotifications(String userId) {
    _userId = userId;
    _isLoading = true;
    _isFirstLoad = true;
    notifyListeners();

    // Re-register FCM token
    _pushNotificationService?.updateToken(userId);

    _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            _notifications = snapshot.docs
                .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
                .toList();

            // Show local notification for new items after initial load
            if (!_isFirstLoad && snapshot.docChanges.isNotEmpty) {
              for (var change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  final data = change.doc.data() as Map<String, dynamic>;
                  _pushNotificationService?.showLocalNotification(
                    title: data['title'] ?? 'New Notification',
                    body: data['body'] ?? '',
                    route: data['route'],
                  );
                }
              }
            }

            _isFirstLoad = false;
            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            debugPrint("Error loading notifications: $e");
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> markAsRead(String notificationId) async {
    if (_userId == null) return;

    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        body: _notifications[index].body,
        type: _notifications[index].type,
        isRead: true,
        createdAt: _notifications[index].createdAt,
      );
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    }
  }

  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    final batch = _firestore.batch();
    final col = _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications');

    for (var notif in _notifications.where((n) => !n.isRead)) {
      notif = NotificationModel(
        id: notif.id,
        title: notif.title,
        body: notif.body,
        type: notif.type,
        isRead: true,
        createdAt: notif.createdAt,
      );
      batch.update(col.doc(notif.id), {'isRead': true});
    }
    notifyListeners();
    await batch.commit();
  }

  Future<void> clearAllNotifications() async {
    if (_userId == null) return;

    final batch = _firestore.batch();
    final col = _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications');

    final snapshot = await col.get();
    if (snapshot.docs.isEmpty) return;

    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    _notifications.clear();
    notifyListeners();

    await batch.commit();
  }
}

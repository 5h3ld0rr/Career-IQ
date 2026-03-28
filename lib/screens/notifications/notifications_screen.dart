import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.userId != null) {
        Provider.of<NotificationProvider>(context, listen: false).loadUserNotifications(auth.userId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final notifications = notificationProvider.notifications;
              final isLoading = notificationProvider.isLoading;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _buildGlassBox(
                        context,
                        borderRadius: 50,
                        padding: const EdgeInsets.all(4),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    title: const Text(
                      'Notifications',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    centerTitle: true,
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(24),
                    sliver: isLoading 
                      ? const SliverFillRemaining(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : notifications.isEmpty
                        ? SliverFillRemaining(
                            child: _buildEmptyState(context),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final notif = notifications[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildNotificationItem(
                                    context,
                                    notif.id,
                                    notif.title,
                                    notif.body,
                                    _formatTime(notif.createdAt),
                                    _getIconForType(notif.type),
                                    _getColorForType(notif.type),
                                    notif.isRead,
                                    notif.type,
                                  ),
                                );
                              },
                              childCount: notifications.length,
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
            // Demo Simulator
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.userId != null) {
              Provider.of<NotificationProvider>(context, listen: false).pushService?.simulateNotification(
                'Application Update', 
                'Your application for Software Engineer at Figma has been updated to "Accepted".', 
                'application',
                auth.userId!,
              );
            }
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.send_rounded, color: Colors.blue),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inDays > 1) {
      return DateFormat('MMM d, h:mm a').format(time);
    } else if (difference.inDays == 1) {
      return '1 day ago';
    } else if (difference.inHours > 0) {
      return '\${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '\${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'application': return Icons.work_history_rounded;
      case 'reminder': return Icons.event_available_rounded;
      case 'job': return Icons.auto_awesome_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'application': return Colors.blueAccent;
      case 'reminder': return Colors.orangeAccent;
      case 'job': return Colors.purpleAccent;
      default: return Colors.greenAccent;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return _buildGlassBox(
      context,
      disableBlur: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_rounded, size: 64, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'We will notify you when there are updates.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: 100,
      left: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF81D4FA).withValues(alpha: 0.35),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBox(
    BuildContext context, {
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = 28,
    bool disableBlur = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(context),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.light
                  ? 0.04
                  : 0.2,
            ),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: disableBlur ? Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ) : BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    BuildContext context,
    String id,
    String title,
    String message,
    String time,
    IconData icon,
    Color iconColor,
    bool isRead,
    String type,
  ) {
    return GestureDetector(
      onTap: () {
        Provider.of<NotificationProvider>(context, listen: false).markAsRead(id);
        // Add navigation logic if requested
      },
      child: _buildGlassBox(
        context,
        disableBlur: true,
        borderRadius: 24,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !isRead ? iconColor : Colors.transparent, 
                  width: 1.5
                )
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: !isRead ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

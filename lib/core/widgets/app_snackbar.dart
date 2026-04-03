import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:careeriq/main.dart';

class AppSnackBar {
  static void show(String message, {bool isError = false}) {
    String cleanMessage = _getFriendlyErrorMessage(message);
    if (cleanMessage.isEmpty) {
      return;
    }

    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        duration: const Duration(seconds: 4),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isError
                      ? [
                          Colors.redAccent.shade700.withValues(alpha: 0.8),
                          Colors.redAccent.shade400.withValues(alpha: 0.6),
                        ]
                      : [
                          const Color(0xFF03A9F4).withValues(alpha: 0.8),
                          const Color(0xFF0288D1).withValues(alpha: 0.6),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      cleanMessage,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _getFriendlyErrorMessage(String message) {
    if (message.contains('invalid-credential') ||
        message.contains('wrong-password')) {
      return "Invalid email or password. Please try again.";
    }
    if (message.contains('user-not-found')) {
      return "No account found with this email.";
    }
    if (message.contains('email-already-in-use')) {
      return "This email is already registered.";
    }
    if (message.contains('network-request-failed')) {
      return "Network error. Please check your connection.";
    }
    if (message.toLowerCase().contains('cancelled') ||
        message.toLowerCase().contains('abort') ||
        message == 'null') {
      return "";
    }
    if (message.contains('too-many-requests')) {
      return "Too many attempts. Please try again later.";
    }
    if (message.contains('invalid-email')) {
      return "Please enter a valid email address.";
    }

    if (message.contains('dev.flutter.pigeon') ||
        message.contains('platform_interface') ||
        message.contains('HostApi')) {
      return "Authentication service unavailable. Please try again later.";
    }

    if (message.contains('PlatformException')) {
      return "Something went wrong. Please check your inputs and try again.";
    }

    if (message.contains(']')) {
      return message.split(']').last.trim();
    }

    if (message.length > 60 &&
        !message.contains(' ') &&
        message.contains('.')) {
      return "Service error. Please try again in a moment.";
    }

    return message;
  }
}

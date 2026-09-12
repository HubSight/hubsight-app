import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final inAppNotificationServiceProvider =
    Provider<InAppNotificationService>((ref) {
  return InAppNotificationService();
});

class InAppNotificationService {
  GlobalKey<NavigatorState>? _navigatorKey;

  void attachNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  void showNotification({
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message,
              style: const TextStyle(color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF334155)),
        ),
        action: onTap != null
            ? SnackBarAction(
                label: 'View',
                textColor: const Color(0xFFE85D10),
                onPressed: onTap,
              )
            : null,
      ),
    );
  }
}

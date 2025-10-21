import 'dart:html' as html;

/// Helper class for browser notifications
class NotificationHelper {
  /// Check if notifications are supported
  static bool get isSupported {
    return html.Notification.supported;
  }

  /// Get current notification permission status
  static String get permission {
    if (!isSupported) return 'denied';
    return html.Notification.permission ?? 'denied';
  }

  /// Request notification permission from user
  static Future<String> requestPermission() async {
    if (!isSupported) {
      return 'denied';
    }

    if (permission == 'granted') {
      return 'granted';
    }

    try {
      final result = await html.Notification.requestPermission();
      return result;
    } catch (e) {
      print('[NotificationHelper] Error requesting permission: $e');
      return 'denied';
    }
  }

  /// Show a notification
  static Future<void> showNotification({
    required String title,
    String? body,
    String? icon,
    String? badge,
    String? tag,
    bool requireInteraction = false,
  }) async {
    if (!isSupported) {
      print('[NotificationHelper] Notifications not supported');
      return;
    }

    // Request permission if not already granted
    if (permission != 'granted') {
      final result = await requestPermission();
      if (result != 'granted') {
        print('[NotificationHelper] Permission not granted: $result');
        return;
      }
    }

    try {
      final options = <String, dynamic>{
        if (body != null) 'body': body,
        if (icon != null) 'icon': icon,
        if (badge != null) 'badge': badge,
        if (tag != null) 'tag': tag,
        'requireInteraction': requireInteraction,
        'vibrate': [200, 100, 200], // Vibration pattern for mobile
      };

      // Create notification using JS interop
      html.Notification(title, body: body, icon: icon, tag: tag);
      print('[NotificationHelper] Notification shown: $title');
    } catch (e) {
      print('[NotificationHelper] Error showing notification: $e');
    }
  }

  /// Show order success notification
  static Future<void> showOrderSuccessNotification({
    required String orderNumber,
  }) async {
    await showNotification(
      title: 'Order Successful! 🎉',
      body: 'Order #$orderNumber\nPlease proceed to counter for payment.',
      icon: '/icons/Icon-192.png',
      tag: 'order-success',
      requireInteraction: true, // Keep notification visible until user interacts
    );
  }

  /// Show order failure notification
  static Future<void> showOrderFailureNotification({
    required String message,
  }) async {
    await showNotification(
      title: 'Order Failed',
      body: message,
      icon: '/icons/Icon-192.png',
      tag: 'order-failed',
      requireInteraction: false,
    );
  }
}

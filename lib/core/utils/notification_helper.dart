import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter

/// Helper class for browser notifications
class NotificationHelper {
  // Helper to log to browser console (works in release builds)
  static void _log(String message) {
    html.window.console.log('[NotificationHelper] $message');
  }
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
      _log('Notifications not supported in this browser');
      return 'denied';
    }

    if (permission == 'granted') {
      _log('Notification permission already granted');
      return 'granted';
    }

    try {
      _log('Requesting notification permission...');
      final result = await html.Notification.requestPermission();
      _log('Notification permission result: $result');
      return result;
    } catch (e) {
      _log('Error requesting notification permission: $e');
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
    _log('Attempting to show notification: $title');

    if (!isSupported) {
      _log('Notifications not supported - aborting');
      return;
    }

    // Request permission if not already granted
    if (permission != 'granted') {
      _log('Permission not granted, requesting...');
      final result = await requestPermission();
      if (result != 'granted') {
        _log('Permission denied - cannot show notification');
        return;
      }
    }

    try {
      _log('Creating notification with title: $title, body: $body');
      // Create notification - dart:html Notification only supports basic named parameters
      // Additional options like requireInteraction and vibrate are not supported in dart:html
      // For full control, we would need to use package:js for direct JS interop
      html.Notification(
        title,
        body: body,
        icon: icon,
        tag: tag,
      );
      _log('Notification created successfully');
    } catch (e) {
      _log('Error creating notification: $e');
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

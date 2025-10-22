// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Helper class for updating page metadata (title, description) dynamically
class PageMetadataHelper {
  /// Update the browser's page title
  static void updateTitle(String title) {
    html.document.title = title;
  }

  /// Update the meta description tag
  static void updateDescription(String description) {
    final metaDescription = html.document.querySelector('meta[name="description"]');
    if (metaDescription != null) {
      metaDescription.setAttribute('content', description);
    }
  }

  /// Update both title and description for a store
  static void updateForStore(String storeName) {
    final title = '$storeName - Mobile Order';
    final description = 'Order your favorite meals from $storeName online. Pre-order for pickup or dine-in with quick and easy mobile ordering.';

    updateTitle(title);
    updateDescription(description);
  }

  /// Reset to default title and description
  static void resetToDefault() {
    updateTitle('Jeffy Mobile Order');
    updateDescription('Order your favorite meals from Jeffy\'s online. Pre-order for pickup or dine-in with quick and easy mobile ordering.');
  }
}

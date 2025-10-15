import 'package:flutter/material.dart';

/// A web-safe image widget with better error handling
///
/// Note: CORS errors from image servers cannot be fixed client-side.
/// This widget provides graceful fallbacks when images fail to load.
class WebSafeImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const WebSafeImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      // Disable image caching to reduce CORS issues
      cacheWidth: null,
      cacheHeight: null,
      // Better error handling
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Colors.grey[200],
              child: const Icon(
                Icons.restaurant,
                size: 48,
                color: Colors.grey,
              ),
            );
      },
      // Show placeholder while loading
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;

        if (frame == null) {
          return placeholder ??
              Container(
                width: width,
                height: height,
                color: Colors.grey[100],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
        }

        return child;
      },
    );
  }
}

import 'package:flutter/material.dart';

/// Displays the admin-configured church logo, falling back to the bundled mark.
class ChurchLogo extends StatelessWidget {
  const ChurchLogo({super.key, required this.url, required this.size});

  final String url;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Image.asset(
      'assets/icons/logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheHeight: (size * 3).round(),
      semanticLabel: 'Church logo',
    );

    if (url.isEmpty) return fallback();
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => fallback(),
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : SizedBox(
              width: size,
              height: size,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: progress.expectedTotalBytes == null
                      ? null
                      : progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!,
                ),
              ),
            ),
    );
  }
}

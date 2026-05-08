import 'package:flutter/material.dart';

/// Tries multiple image URLs in order until one loads.
class NetworkImageWithFallback extends StatefulWidget {
  const NetworkImageWithFallback({
    super.key,
    required this.urls,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
  });

  final List<String> urls;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  @override
  State<NetworkImageWithFallback> createState() => _NetworkImageWithFallbackState();
}

class _NetworkImageWithFallbackState extends State<NetworkImageWithFallback> {
  int _i = 0;

  void _next() {
    if (_i + 1 >= widget.urls.length) return;
    setState(() => _i += 1);
  }

  @override
  void didUpdateWidget(covariant NetworkImageWithFallback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.urls != widget.urls) {
      _i = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.urls.where((e) => e.trim().isNotEmpty).toList(growable: false);
    if (urls.isEmpty) return widget.placeholder ?? const SizedBox.shrink();
    final url = urls[_i.clamp(0, urls.length - 1)];

    return Image.network(
      url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stack) {
        if (_i + 1 < urls.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _next());
          return widget.placeholder ?? const SizedBox.shrink();
        }
        return widget.placeholder ?? const SizedBox.shrink();
      },
    );
  }
}


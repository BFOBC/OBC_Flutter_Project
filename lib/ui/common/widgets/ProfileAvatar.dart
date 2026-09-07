import 'package:flutter/material.dart';

/// Drop-in CircleAvatar that gracefully falls back to a person icon
/// when the network image URL is empty, null, or fails to load.
class ProfileAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  const ProfileAvatar({
    super.key,
    this.url,
    this.radius = 20,
    this.backgroundColor,
    this.iconColor,
  });

  bool get _hasUrl => url != null && url!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.grey.shade200,
      child: ClipOval(
        child: _hasUrl
            ? Image.network(
                url!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : SizedBox(
                        width: radius * 2,
                        height: radius * 2,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                      ),
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Icon(
          Icons.person,
          size: radius,
          color: iconColor ?? Colors.grey.shade500,
        ),
      );
}

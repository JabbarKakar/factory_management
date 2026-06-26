import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    required this.name,
    this.photoUrl,
    this.radius = 28,
    super.key,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    if (hasPhoto) {
      final size = radius * 2;
      return ClipOval(
        child: Image.network(
          photoUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _InitialsAvatar(
            name: name,
            radius: radius,
          ),
        ),
      );
    }

    return _InitialsAvatar(name: name, radius: radius);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({
    required this.name,
    required this.radius,
  });

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
      child: Text(
        Formatters.userInitials(name),
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.72,
        ),
      ),
    );
  }
}

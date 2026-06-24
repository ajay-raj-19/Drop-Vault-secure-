import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

class UserAvatar extends ConsumerWidget {
  final double size;
  final double borderRadius;
  final Border? border;

  const UserAvatar({
    super.key,
    this.size = 40.0,
    this.borderRadius = 20.0,
    this.border,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final user = authState.user;
    final path = user?.profileImagePath;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarContent;

    if (path != null && path.isNotEmpty) {
      if (path.startsWith('http://') || path.startsWith('https://')) {
        avatarContent = Image.network(
          path,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (ctx, err, st) => _buildPlaceholder(context, isDark),
        );
      } else {
        avatarContent = Image.file(
          File(path),
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (ctx, err, st) => _buildPlaceholder(context, isDark),
        );
      }
    } else {
      avatarContent = _buildPlaceholder(context, isDark);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: border,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - (border != null ? 2.0 : 0.0)),
        child: avatarContent,
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark) {
    return Container(
      width: size,
      height: size,
      color: isDark ? const Color(0xFF242424) : const Color(0xFFF3ECF2),
      child: Icon(
        Icons.person,
        size: size * 0.55,
        color: isDark ? Colors.white24 : Colors.black26,
      ),
    );
  }
}

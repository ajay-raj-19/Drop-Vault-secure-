import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onBackPress;
  final bool showBackButton;

  const GlassAppBar({
    Key? key,
    required this.title,
    this.leading,
    this.actions,
    this.onBackPress,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.8),
              border: const Border(
                bottom: BorderSide(
                  color: Color(0x33CCC4D0), // outlineVariant.withOpacity(0.2)
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (showBackButton)
                        leading ??
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                              onPressed: onBackPress ?? () => Navigator.of(context).pop(),
                              style: IconButton.styleFrom(
                                hoverColor: const Color(0xFFEDE6EC).withOpacity(0.5),
                              ),
                            ),
                      if (showBackButton) const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  if (actions != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

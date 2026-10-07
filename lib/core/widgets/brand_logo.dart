import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

class BrandLogo extends StatelessWidget {
  final double? width;
  final double? height;
  const BrandLogo({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final double defaultWidth = width ?? (MediaQuery.of(context).size.width * 0.25).clamp(80.0, 120.0);

    return Image.asset(
      AppAssets.logo,
      width: defaultWidth,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: defaultWidth,
          height: height ?? defaultWidth,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x4C4A00E0),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.lock_person_rounded,
            size: defaultWidth * 0.5,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

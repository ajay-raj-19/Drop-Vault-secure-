import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

class BrandLogo extends StatefulWidget {
  final double? width;
  final double? height;
  const BrandLogo({super.key, this.width, this.height});

  @override
  State<BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<BrandLogo> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox.shrink();
    }

    final double width = widget.width ?? (MediaQuery.of(context).size.width * 0.25).clamp(80.0, 120.0);

    return Image.asset(
      AppAssets.logo,
      width: width,
      height: widget.height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _hasError = true;
            });
          }
        });
        return const SizedBox.shrink();
      },
    );
  }
}

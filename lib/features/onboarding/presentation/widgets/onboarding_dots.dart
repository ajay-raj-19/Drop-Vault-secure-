import 'package:flutter/material.dart';

class OnboardingDots extends StatelessWidget {
  final PageController controller;
  final int pageCount;
  final Color activeColor;
  final Color inactiveColor;

  const OnboardingDots({
    super.key,
    required this.controller,
    required this.pageCount,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        double page = 0.0;
        if (controller.hasClients) {
          page = controller.page ?? controller.initialPage.toDouble();
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pageCount, (index) {
            double distance = (page - index).abs();
            double activeFraction = (1.0 - distance).clamp(0.0, 1.0);

            // Interpolating size and color smoothly
            double width = 8.0 + (24.0 * activeFraction); // Animates between 8.0 and 32.0
            double height = 6.0;

            Color color = Color.lerp(inactiveColor, activeColor, activeFraction) ?? inactiveColor;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(9999),
              ),
            );
          }),
        );
      },
    );
  }
}

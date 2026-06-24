import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class MainLayoutShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutShell({
    Key? key,
    required this.navigationShell,
  }) : super(key: key);

  @override
  State<MainLayoutShell> createState() => _MainLayoutShellState();
}

class _MainLayoutShellState extends State<MainLayoutShell> {
  DateTime? _lastPressed;

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final currentIndex = widget.navigationShell.currentIndex;
        if (currentIndex != 0) {
          // Route back to home branch
          _onTap(0);
        } else {
          // Double press exit behavior on home screen
          final now = DateTime.now();
          if (_lastPressed == null || now.difference(_lastPressed!) > const Duration(seconds: 2)) {
            _lastPressed = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit'),
                duration: Duration(seconds: 2),
              ),
            );
          } else {
            await SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }
        }
      },
      child: Scaffold(
        body: widget.navigationShell,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 32, top: 16, left: 16, right: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Theme.of(context).scaffoldBackgroundColor,
          border: isDark
              ? const Border(
                  top: BorderSide(
                    color: Color(0x14FFFFFF), // rgba(255,255,255,0.08)
                    width: 1,
                  ),
                )
              : null,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : const Color(0xFF6D528E).withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, -10),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.home, 'Home'),
            _buildNavItem(context, 1, Icons.search, 'Search'),
            _buildAddFabItem(context, 2),
            _buildNavItem(context, 3, Icons.folder_open, 'Vaults'),
            _buildNavItem(context, 4, Icons.person, 'Profile'),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildNavItem(BuildContext context, int index, IconData icon, String label) {
    final isActive = widget.navigationShell.currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Inactive color: #8A8A8A
    const inactiveColor = Color(0xFF8A8A8A);

    return GestureDetector(
      onTap: () => _onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: EdgeInsets.symmetric(horizontal: isActive ? 16 : 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: isActive
              ? (isDark
                  ? const LinearGradient(
                      colors: [Color(0xFF210440), Color(0xFF6D28D9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF6D528E), Color(0xFF8A4F39)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ))
              : null,
          boxShadow: isActive
              ? [
                  if (isDark)
                    BoxShadow(
                      color: const Color(0xFF6D28D9).withOpacity(0.4),
                      blurRadius: 10,
                      spreadRadius: 1,
                      offset: const Offset(0, 2),
                    )
                  else
                    BoxShadow(
                      color: const Color(0xFF6D528E).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                ]
              : [],
        ),
        child: AnimatedScale(
          scale: isActive ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 250),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive ? Colors.white : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddFabItem(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _onTap(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? null : Theme.of(context).colorScheme.primary,
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF6D528E), Color(0xFF8A4F39)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          shape: BoxShape.circle,
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: const Color(0xFF6D528E).withOpacity(0.5),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              )
            else
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
          ],
        ),
        child: Icon(
          Icons.add,
          color: isDark ? Colors.white : Theme.of(context).colorScheme.onPrimary,
          size: 32,
        ),
      ),
    );
  }
}

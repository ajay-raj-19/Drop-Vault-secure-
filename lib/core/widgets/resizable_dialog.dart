import 'package:flutter/material.dart';

/// A dialog that allows resizing by dragging the bottom-right corner.
/// Tailored for native-like Windows desktop dialog experience.
class ResizableDialog extends StatefulWidget {
  final Widget title;
  final Widget content;
  final List<Widget>? actions;
  final Size initialSize;
  final double minWidth;
  final double minHeight;
  final double maxWidth;
  final double maxHeight;

  const ResizableDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.initialSize = const Size(600, 500),
    this.minWidth = 350.0,
    this.minHeight = 300.0,
    this.maxWidth = 1000.0,
    this.maxHeight = 800.0,
  });

  @override
  State<ResizableDialog> createState() => _ResizableDialogState();
}

class _ResizableDialogState extends State<ResizableDialog> {
  late double _width;
  late double _height;

  @override
  void initState() {
    super.initState();
    _width = widget.initialSize.width;
    _height = widget.initialSize.height;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Container(
            width: _width,
            height: _height,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Title)
                DefaultTextStyle(
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  child: widget.title,
                ),
                const SizedBox(height: 16),

                // Main Content
                Expanded(
                  child: widget.content,
                ),
                const SizedBox(height: 16),

                // Actions Footer
                if (widget.actions != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: widget.actions!,
                  ),
              ],
            ),
          ),

          // Resize Corner Handle
          Positioned(
            right: 0,
            bottom: 0,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _width = (_width + details.delta.dx).clamp(widget.minWidth, widget.maxWidth);
                  _height = (_height + details.delta.dy).clamp(widget.minHeight, widget.maxHeight);
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.resizeDownRight,
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.bottomRight,
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

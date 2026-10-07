import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import '../utils/manual_refresh_helper.dart';

class DesktopShortcutWrapper extends ConsumerWidget {
  final Widget child;

  const DesktopShortcutWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (kIsWeb || !Platform.isWindows) {
      return child;
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () {
          context.go('/main/add');
        },
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): () {
          context.go('/main/search');
        },
        const SingleActivator(LogicalKeyboardKey.keyE, control: true, shift: true): () {
          context.go('/main/profile/backup');
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () async {
          final undoState = ref.read(undoProvider);
          if (undoState == null) return;

          // Re-add the item to vaultProvider
          await ref.read(vaultProvider.notifier).addItem(undoState.item);

          // Re-add all reminders
          for (final r in undoState.reminders) {
            await ref.read(reminderProvider.notifier).addReminder(r);
          }

          // Remove the item from trashProvider
          await ref.read(trashProvider.notifier).deleteItem(undoState.item.id);

          // Clear the undo state
          ref.read(undoProvider.notifier).clearUndo();

          if (context.mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Restored "${undoState.item.title}" successfully.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        const SingleActivator(LogicalKeyboardKey.keyR, control: true): () async {
          await performManualRefresh(context, ref);
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}

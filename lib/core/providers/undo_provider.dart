import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vault_item.dart';
import '../models/reminder.dart';

class UndoState {
  final VaultItem item;
  final List<Reminder> reminders;

  UndoState({required this.item, required this.reminders});
}

class UndoNotifier extends StateNotifier<UndoState?> {
  UndoNotifier() : super(null);

  void pushUndo(VaultItem item, List<Reminder> reminders) {
    state = UndoState(item: item, reminders: reminders);
  }

  void clearUndo() {
    state = null;
  }
}

final undoProvider = StateNotifierProvider<UndoNotifier, UndoState?>((ref) {
  return UndoNotifier();
});

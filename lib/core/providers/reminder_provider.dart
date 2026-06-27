import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'providers.dart';

class ReminderNotifier extends StateNotifier<List<Reminder>> {
  final ReminderRepository _repository;
  final String _email;

  ReminderNotifier(this._repository, {required String email}) : _email = email, super([]) {
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final list = await _repository.getReminders(_email);
    state = list;
  }

  Future<void> addReminder(Reminder reminder) async {
    await _repository.addReminder(_email, reminder);
    state = [...state, reminder];
  }

  Future<void> toggleReminder(String id) async {
    state = state.map((r) => r.id == id ? r.copyWith(isCompleted: !r.isCompleted) : r).toList();
    final updated = state.firstWhere((r) => r.id == id);
    await _repository.updateReminder(_email, updated);
  }

  Future<void> deleteReminder(String id) async {
    await _repository.deleteReminder(_email, id);
    state = state.where((r) => r.id != id).toList();
  }

  Future<void> reloadReminders() async {
    await _loadReminders();
  }
}

final reminderProvider = StateNotifierProvider<ReminderNotifier, List<Reminder>>((ref) {
  final repository = ref.watch(reminderRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final email = authState.user?.email ?? 'anonymous';
  return ReminderNotifier(repository, email: email);
});

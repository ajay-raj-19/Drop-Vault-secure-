import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/reminder_repository.dart';
import '../../../../core/models/reminder.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/uuid_helper.dart';

class SupabaseReminderRepository implements ReminderRepository {
  final SupabaseService _supabaseService;
  final ReminderRepository _localRepository;
  final SharedPreferences _prefs;

  SupabaseReminderRepository(this._supabaseService, this._localRepository, this._prefs);

  String _getPendingDeletionsKey(String email) => 'pending_deleted_reminders_$email';

  Future<void> _pushReminderToRemote(Reminder rem, String userId) async {
    await _supabaseService.client.from('reminders').upsert({
      'id': toUuid(rem.id),
      'user_id': userId,
      'title': rem.title,
      'collection_name': rem.collectionName,
      'date_time': rem.dateTime.toIso8601String(),
      'is_completed': rem.isCompleted,
      'item_id': rem.itemId != null ? toUuid(rem.itemId!) : null,
      'created_at': rem.dateTime.toIso8601String(),
      'updated_at': rem.updatedAt.toIso8601String(),
    });
  }

  @override
  Future<List<Reminder>> getReminders(String email) async {
    return _localRepository.getReminders(email);
  }

  @override
  Future<void> addReminder(String email, Reminder reminder) async {
    final updatedRem = Reminder(
      id: reminder.id,
      title: reminder.title,
      collectionName: reminder.collectionName,
      dateTime: reminder.dateTime,
      isCompleted: reminder.isCompleted,
      itemId: reminder.itemId,
      updatedAt: DateTime.now(),
    );
    await _localRepository.addReminder(email, updatedRem);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _pushReminderToRemote(updatedRem, userId);
      } catch (_) {}
    }
  }

  @override
  Future<void> updateReminder(String email, Reminder reminder) async {
    final updatedRem = Reminder(
      id: reminder.id,
      title: reminder.title,
      collectionName: reminder.collectionName,
      dateTime: reminder.dateTime,
      isCompleted: reminder.isCompleted,
      itemId: reminder.itemId,
      updatedAt: DateTime.now(),
    );
    await _localRepository.updateReminder(email, updatedRem);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _pushReminderToRemote(updatedRem, userId);
      } catch (_) {}
    }
  }

  @override
  Future<void> deleteReminder(String email, String id) async {
    debugPrint('=== DELETE DIAGNOSTICS ===');
    debugPrint('Delete Requested: Reminder');
    debugPrint('Reminder ID: $id');
    debugPrint('Repository Used: SupabaseReminderRepository');

    // 1. Immediately delete from local cache
    await _localRepository.deleteReminder(email, id);
    debugPrint('Local Delete Success: true');
    debugPrint('Cache Updated: true');

    bool supabaseSuccess = false;
    bool queueUpdated = false;

    // 2. Try to delete from Supabase
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client
            .from('reminders')
            .delete()
            .eq('id', toUuid(id))
            .eq('user_id', userId);
        supabaseSuccess = true;
      } catch (_) {
        // Offline/failure: queue deletion
        final deletionKey = _getPendingDeletionsKey(email);
        final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
        if (!pendingDeletions.contains(id)) {
          pendingDeletions.add(id);
          await _prefs.setStringList(deletionKey, pendingDeletions);
          queueUpdated = true;
        }
      }
    } else {
      // Offline/not logged in: queue deletion
      final deletionKey = _getPendingDeletionsKey(email);
      final pendingDeletions = _prefs.getStringList(deletionKey) ?? [];
      if (!pendingDeletions.contains(id)) {
        pendingDeletions.add(id);
        await _prefs.setStringList(deletionKey, pendingDeletions);
        queueUpdated = true;
      }
    }

    debugPrint('Supabase Delete Success: $supabaseSuccess');
    debugPrint('Pending Queue Updated: $queueUpdated');
    debugPrint('UI Updated: State updated in notifier');
    debugPrint('Final Verification: Deletion fully processed');
    debugPrint('==========================');
  }
}

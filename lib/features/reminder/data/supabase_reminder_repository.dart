import '../domain/reminder_repository.dart';
import '../../../../core/models/reminder.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/uuid_helper.dart';

class SupabaseReminderRepository implements ReminderRepository {
  final SupabaseService _supabaseService;
  final ReminderRepository _localRepository;

  SupabaseReminderRepository(this._supabaseService, this._localRepository);

  @override
  Future<List<Reminder>> getReminders(String email) async {
    final localReminders = await _localRepository.getReminders(email);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        final response = await _supabaseService.client
            .from('reminders')
            .select()
            .eq('user_id', userId)
            .order('date_time', ascending: true);

        final remoteReminders = (response as List).map((json) {
          return Reminder(
            id: json['id'],
            title: json['title'],
            collectionName: json['collection_name'],
            dateTime: DateTime.parse(json['date_time']),
            isCompleted: json['is_completed'] ?? false,
            itemId: json['item_id'],
          );
        }).toList();

        // Sync local cache
        for (final rem in remoteReminders) {
          final localIndex = localReminders.indexWhere((r) => toUuid(r.id) == rem.id);
          if (localIndex == -1) {
            await _localRepository.addReminder(email, rem);
          } else {
            // Update local fields if changed
            final localRem = localReminders[localIndex];
            if (localRem.title != rem.title ||
                localRem.collectionName != rem.collectionName ||
                localRem.dateTime != rem.dateTime ||
                localRem.isCompleted != rem.isCompleted ||
                localRem.itemId != rem.itemId) {
              await _localRepository.updateReminder(email, rem);
            }
          }
        }

        // Return latest state from local cache
        return await _localRepository.getReminders(email);
      } catch (_) {
        // Fallback silently to local cache on network error
      }
    }

    return localReminders;
  }

  @override
  Future<void> addReminder(String email, Reminder reminder) async {
    await _localRepository.addReminder(email, reminder);
    await _syncReminderToCloud(reminder);
  }

  @override
  Future<void> updateReminder(String email, Reminder reminder) async {
    await _localRepository.updateReminder(email, reminder);
    await _syncReminderToCloud(reminder);
  }

  @override
  Future<void> deleteReminder(String email, String id) async {
    await _localRepository.deleteReminder(email, id);

    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client
            .from('reminders')
            .delete()
            .eq('id', toUuid(id))
            .eq('user_id', userId);
      } catch (_) {}
    }
  }

  Future<void> _syncReminderToCloud(Reminder reminder) async {
    if (_supabaseService.isInitialized && _supabaseService.client.auth.currentUser != null) {
      try {
        final userId = _supabaseService.client.auth.currentUser!.id;
        await _supabaseService.client.from('reminders').upsert({
          'id': toUuid(reminder.id),
          'user_id': userId,
          'title': reminder.title,
          'collection_name': reminder.collectionName,
          'date_time': reminder.dateTime.toIso8601String(),
          'is_completed': reminder.isCompleted,
          'item_id': reminder.itemId != null ? toUuid(reminder.itemId!) : null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}
    }
  }
}

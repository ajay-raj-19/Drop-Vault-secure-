import '../../../../core/models/reminder.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getReminders(String email);
  Future<void> addReminder(String email, Reminder reminder);
  Future<void> updateReminder(String email, Reminder reminder);
  Future<void> deleteReminder(String email, String id);
}

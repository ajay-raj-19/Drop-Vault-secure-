import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/reminder_repository.dart';
import '../../../../core/models/reminder.dart';

class LocalReminderRepository implements ReminderRepository {
  final SharedPreferences _prefs;

  LocalReminderRepository(this._prefs);

  String _getKey(String email) => 'reminders_$email';

  @override
  Future<List<Reminder>> getReminders(String email) async {
    final list = _prefs.getStringList(_getKey(email));
    if (list != null) {
      return list.map((itemStr) => Reminder.fromJson(jsonDecode(itemStr))).toList();
    }
    return [];
  }

  @override
  Future<void> addReminder(String email, Reminder reminder) async {
    final reminders = await getReminders(email);
    reminders.add(reminder);
    await _save(email, reminders);
  }

  @override
  Future<void> updateReminder(String email, Reminder reminder) async {
    final reminders = await getReminders(email);
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      reminders[index] = reminder;
      await _save(email, reminders);
    }
  }

  @override
  Future<void> deleteReminder(String email, String id) async {
    final reminders = await getReminders(email);
    reminders.removeWhere((r) => r.id == id);
    await _save(email, reminders);
  }

  Future<void> _save(String email, List<Reminder> reminders) async {
    final list = reminders.map((item) => jsonEncode(item.toJson())).toList();
    await _prefs.setStringList(_getKey(email), list);
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = "themeMode";
  static const String _currencyKey = "currency";
  static const String _reminderTimeKey = "reminderTime";
  static const String _canRemindKey = "canRemind";
  static DateFormat dateFormat = DateFormat("yyyyMMdd");

  late Box _box;

  ThemeMode _themeMode = ThemeMode.system;
  String _currency = "INR";
  String _reminderTime = "09:00";
  Map canRemind = {};
  bool showExpiredReminderAlert = true;

  ThemeMode get themeMode => _themeMode;

  String get currency => _currency;

  String get reminderTime => _reminderTime;

  SettingsProvider() {
    _init();
  }

  Future<void> _init() async {
    _box = Hive.box('settings');

    // Load saved values
    final savedTheme = _box.get(_themeKey, defaultValue: "system");
    final savedCurrency = _box.get(_currencyKey, defaultValue: "INR");
    final savedReminderTime = _box.get(
      _reminderTimeKey,
      defaultValue: _reminderTime,
    );
    canRemind = _box.get(_canRemindKey, defaultValue: {});
    debugPrint('canRemind:::${canRemind.toString()}');
    _themeMode = _stringToThemeMode(savedTheme);
    _currency = savedCurrency;
    _reminderTime = savedReminderTime;

    notifyListeners();
  }

  bool getExpiredReminderAlert() {
    if (canRemind.isNotEmpty) {
      if (canRemind.containsKey(dateFormat.format(DateTime.now()))) {
        debugPrint(
          'this:::${canRemind[dateFormat.format(DateTime.now())]!['expiredReminderAlert']!}',
        );
        showExpiredReminderAlert =
            canRemind[dateFormat.format(
              DateTime.now(),
            )]!['expiredReminderAlert']!;
      }
    }
    debugPrint(
      'showExpiredReminderAlert;::${showExpiredReminderAlert.toString()}',
    );
    return showExpiredReminderAlert;
  }

  setExpiredReminderAlert() {
    canRemind.update(
      dateFormat.format(DateTime.now().add(Duration(days: 1))),
      (value) => {'expiredReminderAlert': false},
      ifAbsent: () => {'expiredReminderAlert': false},
    );
    debugPrint('canRemind udpate:::${canRemind.toString()}');
    _box.put(_canRemindKey, canRemind);
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _box.put(_themeKey, _themeMode.name); // save as string
    notifyListeners();
  }

  void setCurrency(String currency) {
    _currency = currency;
    _box.put(_currencyKey, _currency);
    notifyListeners();
  }

  void setReminderTime(String hhmm) {
    _reminderTime = hhmm;
    _box.put(_reminderTimeKey, _reminderTime);
    notifyListeners();
  }

  // Helper
  ThemeMode _stringToThemeMode(String value) {
    switch (value) {
      case "light":
        return ThemeMode.light;
      case "dark":
        return ThemeMode.dark;
      case "system":
      default:
        return ThemeMode.system;
    }
  }
}

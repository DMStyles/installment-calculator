import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {
  static const _keyDarkMode = 'setting_dark_mode';
  static const _keyNotificationsEnabled = 'setting_notifications_enabled';
  static const _keyNotificationLeadDays = 'setting_notification_lead_days';

  bool _isDarkMode = true;
  bool _notificationsEnabled = true;
  int _notificationLeadDays = 1;

  bool get isDarkMode => _isDarkMode;
  bool get notificationsEnabled => _notificationsEnabled;
  int get notificationLeadDays => _notificationLeadDays;

  /// Load persisted settings from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_keyDarkMode) ?? true;
    _notificationsEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    _notificationLeadDays = prefs.getInt(_keyNotificationLeadDays) ?? 1;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, value);
  }

  Future<void> setNotificationLeadDays(int days) async {
    _notificationLeadDays = days;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyNotificationLeadDays, days);
  }
}

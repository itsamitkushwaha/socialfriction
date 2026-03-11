import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
    );
    _initialized = true;
  }

  /// Shows a usage warning notification
  static Future<void> showUsageWarning(String appName, String timeUsed) async {
    await _plugin.show(
      1,
      '⏰ Screen Time Alert',
      'You\'ve spent $timeUsed on $appName today',
      _buildDetails(channelId: 'usage_alerts', channelName: 'Usage Alerts'),
    );
  }

  /// Shows a bedtime reminder
  static Future<void> showBedtimeReminder() async {
    await _plugin.show(
      2,
      '🌙 Bedtime Reminder',
      'Time to put your phone down and rest.',
      _buildDetails(channelId: 'bedtime', channelName: 'Bedtime Reminder'),
    );
  }

  /// Shows a goal achieved notification
  static Future<void> showGoalAchieved() async {
    await _plugin.show(
      3,
      '🎉 Goal Achieved!',
      'You stayed under your screen time goal today. Keep it up!',
      _buildDetails(channelId: 'goals', channelName: 'Goals'),
    );
  }

  /// Shows a focus session complete notification  
  static Future<void> showFocusComplete(int minutes) async {
    await _plugin.show(
      4,
      '✅ Focus Session Complete',
      'Great job! You focused for $minutes minutes.',
      _buildDetails(channelId: 'focus', channelName: 'Focus Sessions'),
    );
  }

  /// Schedule daily bedtime reminder
  static Future<void> scheduleBedtimeReminder(int hour, int minute) async {
    await _plugin.cancelAll();
    // Schedule repeating daily notification
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bedtime_hour', hour);
    await prefs.setInt('bedtime_minute', minute);
    await prefs.setBool('bedtime_enabled', true);
  }

  static Future<void> cancelBedtimeReminder() async {
    await _plugin.cancel(2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bedtime_enabled', false);
  }

  static NotificationDetails _buildDetails({
    required String channelId,
    required String channelName,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        color: const Color(0xFF7C5CBF),
      ),
    );
  }
}

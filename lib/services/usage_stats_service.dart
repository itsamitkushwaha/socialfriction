import 'package:usage_stats/usage_stats.dart';
import '../models/app_usage.dart';

class UsageStatsService {
  /// Returns per-app usage for today
  Future<List<AppUsage>> getTodayUsage() async {
    return _getUsageForRange(
      DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0),
      DateTime.now(),
    );
  }

  /// Returns per-app usage for the past [days] days
  Future<Map<DateTime, List<AppUsage>>> getWeeklyUsage({int days = 7}) async {
    final Map<DateTime, List<AppUsage>> result = {};
    for (int i = 0; i < days; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      final start = day.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
      final end = i == 0 ? DateTime.now() : start.add(const Duration(days: 1));
      result[start] = await _getUsageForRange(start, end);
    }
    return result;
  }

  Future<List<AppUsage>> _getUsageForRange(DateTime start, DateTime end) async {
    try {
      // Fetch raw events for the exact time range instead of aggregated stats.
      // This allows us to handle screen off events (to prevent ghost time).
      final events = await UsageStats.queryEvents(start, end);

      final Map<String, int> packageUsageMs = {};
      String? currentForegroundApp;
      int? currentAppStartTime;
      bool isScreenOn = true; // Assume screen is on initially, or at least that an app might be resumed

      // Sort events chronologically to process the timeline
      events.sort((a, b) {
        final ta = int.tryParse(a.timeStamp ?? '0') ?? 0;
        final tb = int.tryParse(b.timeStamp ?? '0') ?? 0;
        return ta.compareTo(tb);
      });

      for (final event in events) {
        final pkg = event.packageName;
        final type = event.eventType;
        final timestampStr = event.timeStamp;

        if (type == null || timestampStr == null) continue;

        final timestamp = int.tryParse(timestampStr);
        if (timestamp == null) continue;

        // eventType '1' = ACTIVITY_RESUMED
        // eventType '2' = ACTIVITY_PAUSED
        // eventType '15' = SCREEN_INTERACTIVE (Screen On)
        // eventType '16' = SCREEN_NON_INTERACTIVE (Screen Off)

        if (type == '15') {
          isScreenOn = true;
          // If there was an app technically in foreground, start its timer now that screen is on
          if (currentForegroundApp != null) {
            currentAppStartTime = timestamp;
          }
        } else if (type == '16') {
          isScreenOn = false;
          // Stop timer for current app because screen turned off
          if (currentForegroundApp != null && currentAppStartTime != null) {
            final durationMs = timestamp - currentAppStartTime;
            if (durationMs > 0) {
              packageUsageMs[currentForegroundApp] = (packageUsageMs[currentForegroundApp] ?? 0) + durationMs;
            }
            currentAppStartTime = null; // paused
          }
        } else if (type == '1' && pkg != null) {
          // A new app came to foreground. If there's an existing app, stop its timer.
          if (currentForegroundApp != null && currentForegroundApp != pkg && currentAppStartTime != null) {
             final durationMs = timestamp - currentAppStartTime;
             if (durationMs > 0) {
                 packageUsageMs[currentForegroundApp] = (packageUsageMs[currentForegroundApp] ?? 0) + durationMs;
             }
          }
          currentForegroundApp = pkg;
          if (isScreenOn) {
            currentAppStartTime = timestamp;
          }
        } else if (type == '2' && pkg != null) {
          // App paused. If it's the current app, calculate time.
          if (currentForegroundApp == pkg && currentAppStartTime != null) {
            final durationMs = timestamp - currentAppStartTime;
            if (durationMs > 0) {
              packageUsageMs[pkg] = (packageUsageMs[pkg] ?? 0) + durationMs;
            }
            currentAppStartTime = null;
            // Note: We don't unset currentForegroundApp because a short pause/resume cycle might happen natively,
            // or the screen might just turn off right after this.
          }
        }
      }

      // Handle any app still in the foreground at the 'end' time
      final endTimestamp = end.millisecondsSinceEpoch;
      if (isScreenOn && currentForegroundApp != null && currentAppStartTime != null) {
        final durationMs = endTimestamp - currentAppStartTime;
        if (durationMs > 0) {
          packageUsageMs[currentForegroundApp] = (packageUsageMs[currentForegroundApp] ?? 0) + durationMs;
        }
      }

      final List<AppUsage> result = [];
      packageUsageMs.forEach((packageName, ms) {
        // Filter out very short flashes (< 1 sec) which are often system checks
        if (ms > 1000) {
          result.add(AppUsage(
            packageName: packageName,
            appName: packageName, 
            usageTimeMs: ms,
            date: start,
          ));
        }
      });

      result.sort((a, b) => b.usageTimeMs.compareTo(a.usageTimeMs));
      return result;
    } catch (_) {
      return [];
    }
  }

  /// Returns total screen time in ms for today
  Future<int> getTotalTodayMs() async {
    final usage = await getTodayUsage();
    return usage.fold<int>(0, (sum, u) => sum + u.usageTimeMs);
  }

  /// Checks if Usage Stats permission is granted
  Future<bool> isPermissionGranted() async {
    try {
      final isGranted = await UsageStats.checkUsagePermission();
      return isGranted ?? false;
    } catch (_) {
      return false;
    }
  }
}

extension DateTimeExt on DateTime {
  DateTime copyWith({
    int? year, int? month, int? day,
    int? hour, int? minute, int? second, int? millisecond,
  }) {
    return DateTime(
      year ?? this.year, month ?? this.month, day ?? this.day,
      hour ?? this.hour, minute ?? this.minute,
      second ?? this.second, millisecond ?? this.millisecond,
    );
  }
}

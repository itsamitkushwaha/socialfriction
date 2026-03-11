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
      final stats = await UsageStats.queryUsageStats(start, end);


      final List<AppUsage> result = [];
      for (final stat in stats) {
        final ms = int.tryParse(stat.totalTimeInForeground ?? '0') ?? 0;
        if (ms > 0) {
          result.add(AppUsage(
            packageName: stat.packageName ?? '',
            appName: stat.packageName ?? '',
            usageTimeMs: ms,
            date: start,
          ));
        }
      }

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
      await UsageStats.queryUsageStats(
        DateTime.now().subtract(const Duration(minutes: 1)),
        DateTime.now(),
      );
      return true;
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

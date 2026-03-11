import 'package:flutter/foundation.dart';
import '../models/app_usage.dart';
import '../services/usage_stats_service.dart';

class UsageProvider extends ChangeNotifier {
  final UsageStatsService _service = UsageStatsService();

  List<AppUsage> _todayUsage = [];
  Map<DateTime, List<AppUsage>> _weeklyUsage = {};
  bool _loading = false;
  bool _hasPermission = false;
  int _streak = 0;
  int _dailyGoalMinutes = 120; // 2 hours default

  List<AppUsage> get todayUsage => _todayUsage;
  Map<DateTime, List<AppUsage>> get weeklyUsage => _weeklyUsage;
  bool get loading => _loading;
  bool get hasPermission => _hasPermission;
  int get streak => _streak;
  int get dailyGoalMinutes => _dailyGoalMinutes;

  int get totalTodayMs =>
      _todayUsage.fold(0, (sum, u) => sum + u.usageTimeMs);

  String get totalTodayFormatted {
    final d = Duration(milliseconds: totalTodayMs);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  double get goalProgress {
    if (_dailyGoalMinutes == 0) return 0;
    return (totalTodayMs / 1000 / 60 / _dailyGoalMinutes).clamp(0.0, 1.0);
  }

  bool get isOverGoal => goalProgress >= 1.0;

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    _hasPermission = await _service.isPermissionGranted();
    if (_hasPermission) {
      _todayUsage = await _service.getTodayUsage();
      _weeklyUsage = await _service.getWeeklyUsage();
    }

    _loading = false;
    notifyListeners();
  }

  void setDailyGoal(int minutes) {
    _dailyGoalMinutes = minutes;
    notifyListeners();
  }

  void incrementStreak() {
    _streak++;
    notifyListeners();
  }
}

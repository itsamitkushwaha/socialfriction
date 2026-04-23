import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_usage.dart';
import '../services/usage_stats_service.dart';
import '../services/database_service.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class UsageProvider extends ChangeNotifier with WidgetsBindingObserver {
  final UsageStatsService _service = UsageStatsService();

  List<AppUsage> _todayUsage = [];
  Map<DateTime, List<AppUsage>> _weeklyUsage = {};
  bool _loading = false;
  bool _hasPermission = false;
  int _streak = 0;
  int _dailyGoalMinutes = 120; // 2 hours default

  UsageProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-fetch permission status and data when returning to the app
      loadData();
    }
  }

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
      final todayRaw = await _service.getTodayUsage();
      final weeklyRaw = await _service.getWeeklyUsage();
      
      _todayUsage = await _resolveAppNames(todayRaw);
      
      _weeklyUsage = {};
      for (var entry in weeklyRaw.entries) {
        _weeklyUsage[entry.key] = await _resolveAppNames(entry.value);
      }
    }

    _loading = false;
    notifyListeners();
  }

  // Cache to avoid querying InstalledApps too many times
  Future<List<AppUsage>> _resolveAppNames(List<AppUsage> usages) async {
    // 1. Fetch ALL launchable installed apps to use as an "allowed map"
    // Digital Wellbeing primarily filters for apps that have a launch intent
    // and are not strictly system background services or launchers themselves. 
    // `excludeSystemApps: false` because some pre-installed user apps like YouTube are "system".
    // `excludeNonLaunchableApps: true` effectively drops the launcher and background OS stuff.
    List<AppInfo> installedLaunchableApps = [];
    try {
      installedLaunchableApps = await InstalledApps.getInstalledApps(
        excludeSystemApps: false, 
        excludeNonLaunchableApps: true,
      );
    } catch (_) {
      // ignore
    }

    final Map<String, String> allowedAppsMap = {
      for (var app in installedLaunchableApps)
        app.packageName: app.name
    };

    final List<AppUsage> resolved = [];
    for (final usage in usages) {
      final String pkg = usage.packageName;
      
      // If it doesn't exist in our allowed launchable apps list, drop it entirely.
      if (!allowedAppsMap.containsKey(pkg)) {
        continue;
      }

      final String appName = allowedAppsMap[pkg]!;

      resolved.add(AppUsage(
        packageName: pkg,
        appName: appName,
        usageTimeMs: usage.usageTimeMs,
        date: usage.date,
      ));
    }
    
    return resolved;
  }

  void setDailyGoal(int minutes) {
    _dailyGoalMinutes = minutes;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseService().updateDailyGoal(user.uid, minutes);
    }
  }

  void incrementStreak() {
    _streak++;
    notifyListeners();
  }

  void initializeFromCloud(int goal, int cloudStreak) {
    _dailyGoalMinutes = goal;
    _streak = cloudStreak;
    notifyListeners();
  }
}

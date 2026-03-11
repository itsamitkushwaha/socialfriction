class AppUsage {
  final String packageName;
  final String appName;
  final int usageTimeMs; // milliseconds
  final DateTime date;

  const AppUsage({
    required this.packageName,
    required this.appName,
    required this.usageTimeMs,
    required this.date,
  });

  Duration get usageDuration => Duration(milliseconds: usageTimeMs);

  String get formattedTime {
    final d = usageDuration;
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    } else if (d.inMinutes > 0) {
      return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    } else {
      return '${d.inSeconds}s';
    }
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'usageTimeMs': usageTimeMs,
        'date': date.toIso8601String(),
      };

  factory AppUsage.fromJson(Map<String, dynamic> json) => AppUsage(
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        usageTimeMs: json['usageTimeMs'] as int,
        date: DateTime.parse(json['date'] as String),
      );
}

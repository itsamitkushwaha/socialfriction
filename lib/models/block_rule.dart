enum BlockType { permanent, dailyLimit, schedule, sessionLimit }

class BlockRule {
  final String packageName;
  final String appName;
  final BlockType blockType;
  final int? dailyLimitMinutes;   // For dailyLimit type
  final int? sessionLimitMinutes; // For sessionLimit type
  final String? scheduleStart;    // e.g. "22:00" for schedule type
  final String? scheduleEnd;      // e.g. "07:00"
  final bool isEnabled;

  const BlockRule({
    required this.packageName,
    required this.appName,
    required this.blockType,
    this.dailyLimitMinutes,
    this.sessionLimitMinutes,
    this.scheduleStart,
    this.scheduleEnd,
    this.isEnabled = true,
  });

  BlockRule copyWith({
    String? packageName,
    String? appName,
    BlockType? blockType,
    int? dailyLimitMinutes,
    int? sessionLimitMinutes,
    String? scheduleStart,
    String? scheduleEnd,
    bool? isEnabled,
  }) {
    return BlockRule(
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      blockType: blockType ?? this.blockType,
      dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      sessionLimitMinutes: sessionLimitMinutes ?? this.sessionLimitMinutes,
      scheduleStart: scheduleStart ?? this.scheduleStart,
      scheduleEnd: scheduleEnd ?? this.scheduleEnd,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'packageName': packageName,
        'appName': appName,
        'blockType': blockType.name,
        'dailyLimitMinutes': dailyLimitMinutes,
        'sessionLimitMinutes': sessionLimitMinutes,
        'scheduleStart': scheduleStart,
        'scheduleEnd': scheduleEnd,
        'isEnabled': isEnabled,
      };

  factory BlockRule.fromJson(Map<String, dynamic> json) => BlockRule(
        packageName: json['packageName'] as String,
        appName: json['appName'] as String,
        blockType: BlockType.values.byName(json['blockType'] as String),
        dailyLimitMinutes: json['dailyLimitMinutes'] as int?,
        sessionLimitMinutes: json['sessionLimitMinutes'] as int?,
        scheduleStart: json['scheduleStart'] as String?,
        scheduleEnd: json['scheduleEnd'] as String?,
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  String get description {
    switch (blockType) {
      case BlockType.permanent:
        return 'Blocked permanently';
      case BlockType.dailyLimit:
        return 'Limit: ${dailyLimitMinutes}m/day';
      case BlockType.sessionLimit:
        return 'Session limit: ${sessionLimitMinutes}m';
      case BlockType.schedule:
        return 'Blocked $scheduleStart – $scheduleEnd';
    }
  }
}

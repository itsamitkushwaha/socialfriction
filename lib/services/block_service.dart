import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_rule.dart';

class BlockService {
  static const _rulesKey = 'block_rules';
  static const _keywordsKey = 'blocked_keywords';
  static const _pinKey = 'block_pin';

  // ─── Block Rules ────────────────────────────────────────────────────────────

  Future<List<BlockRule>> getRules() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_rulesKey) ?? [];
    return raw
        .map((e) => BlockRule.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveRules(List<BlockRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _rulesKey,
      rules.map((r) => jsonEncode(r.toJson())).toList(),
    );
    await _syncToNative(rules);
  }

  Future<void> addRule(BlockRule rule) async {
    final rules = await getRules();
    rules.removeWhere((r) => r.packageName == rule.packageName);
    rules.add(rule);
    await saveRules(rules);
  }

  Future<void> removeRule(String packageName) async {
    final rules = await getRules();
    rules.removeWhere((r) => r.packageName == packageName);
    await saveRules(rules);
  }

  Future<void> toggleRule(String packageName) async {
    final rules = await getRules();
    final idx = rules.indexWhere((r) => r.packageName == packageName);
    if (idx != -1) {
      rules[idx] = rules[idx].copyWith(isEnabled: !rules[idx].isEnabled);
      await saveRules(rules);
    }
  }

  Future<bool> isBlocked(String packageName) async {
    final rules = await getRules();
    final rule = rules.where((r) => r.packageName == packageName && r.isEnabled).firstOrNull;
    if (rule == null) return false;

    switch (rule.blockType) {
      case BlockType.permanent:
        return true;
      case BlockType.schedule:
        return _isInSchedule(rule.scheduleStart, rule.scheduleEnd);
      case BlockType.dailyLimit:
      case BlockType.sessionLimit:
        // Native service checks usage time vs limit
        return false;
    }
  }

  bool _isInSchedule(String? start, String? end) {
    if (start == null || end == null) return false;
    final now = TimeOfDay.now();
    final s = _parseTime(start);
    final e = _parseTime(end);
    if (s == null || e == null) return false;
    final nowMins = now.hour * 60 + now.minute;
    final sMins = s.hour * 60 + s.minute;
    final eMins = e.hour * 60 + e.minute;
    if (sMins <= eMins) {
      return nowMins >= sMins && nowMins <= eMins;
    } else {
      // Overnight e.g. 22:00 – 07:00
      return nowMins >= sMins || nowMins <= eMins;
    }
  }

  TimeOfDay? _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  // Syncs block list to native SharedPreferences for Kotlin accessibility service
  Future<void> _syncToNative(List<BlockRule> rules) async {
    final prefs = await SharedPreferences.getInstance();
    final blocked = rules
        .where((r) => r.isEnabled && r.blockType == BlockType.permanent)
        .map((r) => r.packageName)
        .toList();
    await prefs.setString('native_blocked_packages', jsonEncode(blocked));
  }

  // ─── Keywords ───────────────────────────────────────────────────────────────

  Future<List<String>> getKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keywordsKey) ?? [];
  }

  Future<void> addKeyword(String keyword) async {
    final kws = await getKeywords();
    if (!kws.contains(keyword.toLowerCase())) {
      kws.add(keyword.toLowerCase());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_keywordsKey, kws);
    }
  }

  Future<void> removeKeyword(String keyword) async {
    final kws = await getKeywords();
    kws.removeWhere((k) => k == keyword.toLowerCase());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keywordsKey, kws);
  }

  // ─── PIN ────────────────────────────────────────────────────────────────────

  Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_pinKey);
  }

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pinKey) == pin;
  }

  Future<void> clearPin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
  }

  // ─── Accessibility Service ─────────────────────────────────────────────────

  Future<bool> isAccessibilityServiceEnabled() async {
    // This is checked natively; we use a flag written by Kotlin
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('accessibility_service_enabled') ?? false;
  }
}

class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});

  static TimeOfDay now() {
    final d = DateTime.now();
    return TimeOfDay(hour: d.hour, minute: d.minute);
  }
}

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/block_rule.dart';

class BlockService {
  static const _rulesKey = 'block_rules';
  static const _keywordsKey = 'blocked_keywords';
  static const _pinKey = 'block_pin';

  static const MethodChannel _channel = MethodChannel("social_friction/blocker");

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
    await syncRules(rules);
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
    return rules.any((r) => r.packageName == packageName && r.isEnabled);
  }

  // ─── Native Sync ────────────────────────────────────────────────────────────

  Future<void> syncRules(List<BlockRule> rules) async {
    try {
      final jsonRules = rules.map((r) => r.toJson()).toList();
      await _channel.invokeMethod("updateRules", jsonRules);
    } catch (_) {
    }
  }

  Future<void> syncRulesToNative() async {
    final rules = await getRules();
    await syncRules(rules);
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

  Future<void> saveKeywords(List<String> keywords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keywordsKey, keywords);
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

  Future<bool> isOverlayPermissionGranted() async {
    try {
      final granted = await _channel.invokeMethod<bool>('checkOverlayPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod('requestOverlayPermission');
    } catch (_) {}
  }

  // ─── Accessibility Service ─────────────────────────────────────────────────

  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final enabled = await _channel.invokeMethod<bool>('isAccessibilityServiceEnabled');
      return enabled ?? false;
    } catch (_) {
      return false;
    }
  }
}

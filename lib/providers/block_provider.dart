import 'package:flutter/foundation.dart';
import '../models/block_rule.dart';
import '../services/block_service.dart';

class BlockProvider extends ChangeNotifier {
  final BlockService _service = BlockService();

  List<BlockRule> _rules = [];
  List<String> _keywords = [];
  bool _loading = false;
  bool _accessibilityEnabled = false;
  bool _hasPin = false;

  List<BlockRule> get rules => _rules;
  List<String> get keywords => _keywords;
  bool get loading => _loading;
  bool get accessibilityEnabled => _accessibilityEnabled;
  bool get hasPin => _hasPin;
  int get blockedAppCount => _rules.where((r) => r.isEnabled).length;

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    _rules = await _service.getRules();
    _keywords = await _service.getKeywords();
    _accessibilityEnabled = await _service.isAccessibilityServiceEnabled();
    _hasPin = await _service.hasPin();

    _loading = false;
    notifyListeners();
  }

  Future<void> addRule(BlockRule rule) async {
    await _service.addRule(rule);
    await loadData();
  }

  Future<void> removeRule(String packageName) async {
    await _service.removeRule(packageName);
    await loadData();
  }

  Future<void> toggleRule(String packageName) async {
    await _service.toggleRule(packageName);
    await loadData();
  }

  bool isBlocked(String packageName) {
    return _rules.any((r) => r.packageName == packageName && r.isEnabled);
  }

  Future<void> addKeyword(String kw) async {
    await _service.addKeyword(kw);
    _keywords = await _service.getKeywords();
    notifyListeners();
  }

  Future<void> removeKeyword(String kw) async {
    await _service.removeKeyword(kw);
    _keywords = await _service.getKeywords();
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    _hasPin = true;
    notifyListeners();
  }

  Future<bool> verifyPin(String pin) => _service.verifyPin(pin);

  Future<void> clearPin() async {
    await _service.clearPin();
    _hasPin = false;
    notifyListeners();
  }
}

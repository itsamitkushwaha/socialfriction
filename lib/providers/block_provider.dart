import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/block_rule.dart';
import '../services/block_service.dart';
import '../services/database_service.dart';

/// State manager for the app-blocking feature.
///
/// Implements [WidgetsBindingObserver] so that the accessibility service
/// status is re-checked every time the user returns to the app — ensuring the
/// UI reflects the correct state after the user enables/disables the service
/// from Android Settings.
class BlockProvider extends ChangeNotifier with WidgetsBindingObserver {
  final BlockService _service = BlockService();

  List<BlockRule> _rules = [];
  List<String> _keywords = [];
  bool _loading = false;
  bool _accessibilityEnabled = false;
  bool _overlayPermissionGranted = false;
  bool _hasPin = false;

  List<BlockRule> get rules => _rules;
  List<String> get keywords => _keywords;
  bool get loading => _loading;
  bool get accessibilityEnabled => _accessibilityEnabled;
  bool get overlayPermissionGranted => _overlayPermissionGranted;
  bool get hasPin => _hasPin;
  int get blockedAppCount => _rules.where((r) => r.isEnabled).length;

  BlockProvider() {
    // Register for app-lifecycle events so we can detect when the user
    // returns from the system Accessibility Settings screen.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check accessibility status and re-sync blocked rules whenever the
      // app comes back to the foreground (e.g. after visiting Settings).
      _refreshOnResume();
    }
  }

  Future<void> _refreshOnResume() async {
    final enabled = await _service.isAccessibilityServiceEnabled();
    final overlay = await _service.isOverlayPermissionGranted();
    if (enabled != _accessibilityEnabled || overlay != _overlayPermissionGranted) {
      _accessibilityEnabled = enabled;
      _overlayPermissionGranted = overlay;
      notifyListeners();
    }
    // Ensure the native service has the latest rules
    await _service.syncRulesToNative();
  }

  // ─── Cloud Initialization ───────────────────────────────────────────────────
  
  Future<void> initializeFromCloud(
    List<BlockRule> cloudRules,
    List<String> cloudKeywords,
    bool cloudHasPin,
  ) async {
    _rules = cloudRules;
    _keywords = cloudKeywords;
    _hasPin = cloudHasPin;
    
    // Overwrite local limits so native Android code stays in sync
    await _service.saveRules(cloudRules);
    await _service.saveKeywords(cloudKeywords);
    
    // Initialize the native blocker logic directly
    await _service.syncRulesToNative();
    
    notifyListeners();
  }

  // ─── Data Loading ───────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _loading = true;
    notifyListeners();

    _rules = await _service.getRules();
    _keywords = await _service.getKeywords();
    _accessibilityEnabled = await _service.isAccessibilityServiceEnabled();
    _overlayPermissionGranted = await _service.isOverlayPermissionGranted();
    _hasPin = await _service.hasPin();

    // Always sync rules to native on startup
    await _service.syncRulesToNative();

    _loading = false;
    notifyListeners();
  }

  Future<void> requestOverlayPermission() async {
    await _service.requestOverlayPermission();
  }

  // ─── Rule Management ────────────────────────────────────────────────────────

  void _syncRules() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseService().syncBlockRules(user.uid, _rules);
    }
  }

  Future<void> addRule(BlockRule rule) async {
    await _service.addRule(rule);
    await loadData();
    _syncRules();
  }

  Future<void> removeRule(String packageName) async {
    await _service.removeRule(packageName);
    await loadData();
    _syncRules();
  }

  Future<void> toggleRule(String packageName) async {
    await _service.toggleRule(packageName);
    await loadData();
    _syncRules();
  }

  bool isBlocked(String packageName) {
    return _rules.any((r) => r.packageName == packageName && r.isEnabled);
  }

  // ─── Keywords ───────────────────────────────────────────────────────────────

  void _syncKeywords() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseService().syncKeywords(user.uid, _keywords);
    }
  }

  Future<void> addKeyword(String kw) async {
    await _service.addKeyword(kw);
    _keywords = await _service.getKeywords();
    notifyListeners();
    _syncKeywords();
  }

  Future<void> removeKeyword(String kw) async {
    await _service.removeKeyword(kw);
    _keywords = await _service.getKeywords();
    notifyListeners();
    _syncKeywords();
  }

  // ─── PIN ────────────────────────────────────────────────────────────────────

  void _syncPinStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseService().syncPinStatus(user.uid, _hasPin);
    }
  }

  Future<void> setPin(String pin) async {
    await _service.setPin(pin);
    _hasPin = true;
    notifyListeners();
    _syncPinStatus();
  }

  Future<bool> verifyPin(String pin) => _service.verifyPin(pin);

  Future<void> clearPin() async {
    await _service.clearPin();
    _hasPin = false;
    notifyListeners();
    _syncPinStatus();
  }
}

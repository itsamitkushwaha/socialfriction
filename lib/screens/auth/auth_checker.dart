import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usage_provider.dart';
import '../../providers/block_provider.dart';
import '../../models/block_rule.dart';
import '../../main.dart'; // To access MainShell
import 'login_screen.dart';
import '../../theme/app_theme.dart';

class AuthChecker extends StatefulWidget {
  const AuthChecker({super.key});

  @override
  State<AuthChecker> createState() => _AuthCheckerState();
}

class _AuthCheckerState extends State<AuthChecker> {
  bool _initialized = false;
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show loading indicator while Firebase initializes auth state
    if (auth.isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    if (auth.isAuthenticated) {
      if (auth.user?.uid != _lastUid) {
        _initialized = false;
        _lastUid = auth.user?.uid;
      }

      final profile = auth.userProfile;
      if (profile != null && !_initialized) {
        _initialized = true;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          final usage = context.read<UsageProvider>();
          final block = context.read<BlockProvider>();

          usage.initializeFromCloud(
            profile['dailyGoalMinutes'] ?? 120,
            profile['streak'] ?? 0,
          );

          final rulesRaw = profile['block_rules'] as List<dynamic>? ?? [];
          final rules = rulesRaw
              .map((e) => BlockRule.fromJson(e as Map<String, dynamic>))
              .toList();

          final keywordsRaw = profile['keywords'] as List<dynamic>? ?? [];
          final keywords = keywordsRaw.map((e) => e.toString()).toList();

          final hasPin = profile['hasPin'] ?? false;

          block.initializeFromCloud(rules, keywords, hasPin);
        });
      }
      return const MainShell();
    } else {
      _initialized = false;
      _lastUid = null;
      return const LoginScreen();
    }
  }
}

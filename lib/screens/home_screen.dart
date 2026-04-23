import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:usage_stats/usage_stats.dart';
import '../theme/app_theme.dart';
import '../providers/usage_provider.dart';
import '../models/app_usage.dart';
import 'app_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        // Hamburger icon — opens the side drawer
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 26),
          tooltip: 'Menu',
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/logo.png',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text('Social Friction'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<UsageProvider>().loadData(),
          ),
        ],
      ),
      body: Consumer<UsageProvider>(
        builder: (ctx, usage, _) {
          if (usage.loading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (!usage.hasPermission) {
            return _PermissionBanner();
          }

          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () => usage.loadData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StreakCard(streak: usage.streak),
                const SizedBox(height: 16),
                _DailyRingCard(usage: usage),
                const SizedBox(height: 16),
                _TopAppsCard(apps: usage.todayUsage.take(5).toList()),
                const SizedBox(height: 16),
                _AssistantTipCard(usage: usage),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Permission Banner ─────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.primary,
                size: 56,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Usage Access Required',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Grant Usage Access permission to see your screen time stats.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {
                UsageStats.grantUsagePermission();
              },
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Streak Card ───────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0D3B), Color(0xFF0D1B2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Day Streak',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'Stay focused and break the habit!',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primary),
            ),
            child: Text(
              '$streak 🏆',
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Daily Ring Card ───────────────────────────────────────────────────────────

class _DailyRingCard extends StatelessWidget {
  final UsageProvider usage;
  const _DailyRingCard({required this.usage});

  @override
  Widget build(BuildContext context) {
    final progress = usage.goalProgress;
    final isOver = usage.isOverGoal;
    final color = isOver ? AppTheme.danger : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Screen Time',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (isOver ? AppTheme.danger : AppTheme.success)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isOver ? 'Over Limit' : 'On Track',
                  style: TextStyle(
                    color: isOver ? AppTheme.danger : AppTheme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            width: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RingPainter(progress: progress, color: color),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      usage.totalTodayFormatted,
                      style: TextStyle(
                        color: color,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'of ${usage.dailyGoalMinutes}m goal',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends StatelessWidget {
  final double progress;
  final Color color;
  const _RingPainter({required this.progress, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CircularRingPainter(progress: progress, color: color),
      size: const Size(160, 160),
    );
  }
}

class _CircularRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircularRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    final strokeWidth = 14.0;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.surfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CircularRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ─── Top Apps Card ─────────────────────────────────────────────────────────────

class _TopAppsCard extends StatelessWidget {
  final List<AppUsage> apps;
  const _TopAppsCard({required this.apps});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Apps Today',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          if (apps.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No usage data yet',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...apps.asMap().entries.map(
              (e) => _AppUsageRow(
                app: e.value,
                color:
                    AppTheme.chartColors[e.key % AppTheme.chartColors.length],
                maxMs: apps.first.usageTimeMs,
              ),
            ),
        ],
      ),
    );
  }
}

class _AppUsageRow extends StatelessWidget {
  final AppUsage app;
  final Color color;
  final int maxMs;
  const _AppUsageRow({
    required this.app,
    required this.color,
    required this.maxMs,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxMs > 0 ? app.usageTimeMs / maxMs : 0.0;
    final name = app.appName.split('.').last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _capitalize(name),
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                app.formattedTime,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: AppTheme.surfaceLight,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Assistant Tip Card ─────────────────────────────────────────────────────────

class _AssistantTipCard extends StatelessWidget {
  final UsageProvider usage;
  const _AssistantTipCard({required this.usage});

  String get _tip {
    final mins = usage.totalTodayMs ~/ 1000 ~/ 60;
    if (mins > 180) {
      return 'You\'ve been on your phone for over 3 hours. Try a 30-minute break!';
    }
    if (mins > 60) {
      return 'Good awareness! Keep screen time under your daily goal.';
    }
    return 'Great start! Stay mindful of your screen time today.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Usage Assistant',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tip,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

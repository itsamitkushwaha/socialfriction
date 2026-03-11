import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/usage_provider.dart';
import '../models/app_usage.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage Stats'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: Consumer<UsageProvider>(
        builder: (ctx, usage, _) {
          if (usage.loading) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.primary));
          }
          if (!usage.hasPermission) {
            return const Center(
              child: Text('Grant Usage Access to see stats',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }
          return TabBarView(
            controller: _tab,
            children: [
              _TodayTab(apps: usage.todayUsage),
              _WeeklyTab(weekly: usage.weeklyUsage),
            ],
          );
        },
      ),
    );
  }
}

// ─── Today Tab ─────────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final List<AppUsage> apps;
  const _TodayTab({required this.apps});

  @override
  Widget build(BuildContext context) {
    if (apps.isEmpty) {
      return const Center(
        child: Text('No usage data for today',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final total = apps.fold(0, (s, a) => s + a.usageTimeMs);
    final top5 = apps.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card
        _SummaryCard(total: total, appCount: apps.length),
        const SizedBox(height: 16),
        // Donut chart
        _DonutChartCard(apps: top5, total: total),
        const SizedBox(height: 16),
        // App list
        _AppListCard(apps: apps),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int appCount;
  const _SummaryCard({required this.total, required this.appCount});

  String _format(int ms) {
    final d = Duration(milliseconds: ms);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.3), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Total Time', value: _format(total)),
          Container(width: 1, height: 40, color: AppTheme.cardBorder),
          _Stat(label: 'Apps Used', value: '$appCount'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      ],
    );
  }
}

class _DonutChartCard extends StatefulWidget {
  final List<AppUsage> apps;
  final int total;
  const _DonutChartCard({required this.apps, required this.total});

  @override
  State<_DonutChartCard> createState() => _DonutChartCardState();
}

class _DonutChartCardState extends State<_DonutChartCard> {
  int _touchedIndex = -1;

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
          const Text('Usage Breakdown',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                height: 160,
                width: 160,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (e, r) {
                        setState(() {
                          _touchedIndex = r?.touchedSection?.touchedSectionIndex ?? -1;
                        });
                      },
                    ),
                    sectionsSpace: 2,
                    centerSpaceRadius: 48,
                    sections: widget.apps.asMap().entries.map((e) {
                      final isTouched = e.key == _touchedIndex;
                      final pct = widget.total > 0
                          ? (e.value.usageTimeMs / widget.total * 100)
                          : 0.0;
                      return PieChartSectionData(
                        color: AppTheme.chartColors[e.key % AppTheme.chartColors.length],
                        value: e.value.usageTimeMs.toDouble(),
                        title: '${pct.toStringAsFixed(0)}%',
                        radius: isTouched ? 52 : 44,
                        titleStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.apps.asMap().entries.map((e) {
                    final name = e.value.appName.split('.').last;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: AppTheme.chartColors[
                                  e.key % AppTheme.chartColors.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _cap(name),
                              style: const TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _AppListCard extends StatelessWidget {
  final List<AppUsage> apps;
  const _AppListCard({required this.apps});

  @override
  Widget build(BuildContext context) {
    final total = apps.fold(0, (s, a) => s + a.usageTimeMs);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('All Apps',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16)),
          ),
          const Divider(color: AppTheme.cardBorder, height: 1),
          ...apps.asMap().entries.map((e) {
            final pct = total > 0 ? e.value.usageTimeMs / total : 0.0;
            final name = e.value.appName.split('.').last;
            return Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.chartColors[e.key % AppTheme.chartColors.length]
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        name[0].toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.chartColors[
                              e.key % AppTheme.chartColors.length],
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    _cap(name),
                    style: const TextStyle(color: AppTheme.textPrimary),
                  ),
                  subtitle: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.surfaceLight,
                    valueColor: AlwaysStoppedAnimation(
                      AppTheme.chartColors[e.key % AppTheme.chartColors.length],
                    ),
                    minHeight: 3,
                  ),
                  trailing: Text(
                    e.value.formattedTime,
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ),
                if (e.key < apps.length - 1)
                  const Divider(
                      color: AppTheme.cardBorder, height: 1, indent: 72),
              ],
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Weekly Tab ────────────────────────────────────────────────────────────────

class _WeeklyTab extends StatelessWidget {
  final Map<DateTime, List<AppUsage>> weekly;
  const _WeeklyTab({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final sorted = weekly.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final days = sorted.map((e) {
      final total = e.value.fold(0, (s, a) => s + a.usageTimeMs);
      return _DayBar(
          day: _dayLabel(e.key), totalMs: total, maxMs: _maxMs(sorted));
    }).toList();

    final totalWeekMs = sorted.fold(
        0, (s, e) => s + e.value.fold(0, (s2, a) => s2 + a.usageTimeMs));
    final avgMs = sorted.isNotEmpty ? totalWeekMs ~/ sorted.length : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _WeeklySummaryCard(totalMs: totalWeekMs, avgMs: avgMs),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Weekly Usage',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16)),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: days,
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _maxMs(List<MapEntry<DateTime, List<AppUsage>>> sorted) {
    int max = 1;
    for (final e in sorted) {
      final t = e.value.fold(0, (s, a) => s + a.usageTimeMs);
      if (t > max) max = t;
    }
    return max;
  }

  String _dayLabel(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}

class _DayBar extends StatelessWidget {
  final String day;
  final int totalMs;
  final int maxMs;

  const _DayBar({required this.day, required this.totalMs, required this.maxMs});

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    if (d.inHours > 0) return '${d.inHours}h';
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = maxMs > 0 ? totalMs / maxMs : 0.0;
    final h = 100.0 * ratio;

    return Column(
      children: [
        Text(_fmt(totalMs),
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Container(
          width: 28,
          height: h.clamp(4.0, 100.0),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(day,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final int totalMs;
  final int avgMs;
  const _WeeklySummaryCard({required this.totalMs, required this.avgMs});

  String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary.withValues(alpha: 0.25), AppTheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'This Week', value: _fmt(totalMs)),
          Container(width: 1, height: 40, color: AppTheme.cardBorder),
          _Stat(label: 'Daily Avg', value: _fmt(avgMs)),
        ],
      ),
    );
  }
}



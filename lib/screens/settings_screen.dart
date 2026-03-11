import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import '../theme/app_theme.dart';
import '../providers/usage_provider.dart';
import '../providers/block_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bedtimeEnabled = false;
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 0);
  bool _remindersEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bedtimeEnabled = prefs.getBool('bedtime_enabled') ?? false;
      final h = prefs.getInt('bedtime_hour') ?? 22;
      final m = prefs.getInt('bedtime_minute') ?? 0;
      _bedtime = TimeOfDay(hour: h, minute: m);
      _remindersEnabled = prefs.getBool('reminders_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminders_enabled', _remindersEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final usage = context.watch<UsageProvider>();
    final block = context.watch<BlockProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Usage Goal
          _SectionHeader('Usage Goals'),
          _GoalCard(usage: usage),
          const SizedBox(height: 20),

          // Notifications
          _SectionHeader('Notifications'),
          _Card(
            children: [
              _ToggleTile(
                icon: Icons.notifications_rounded,
                title: 'Usage Reminders',
                subtitle: 'Get notified when reaching your limit',
                value: _remindersEnabled,
                onChanged: (v) {
                  setState(() => _remindersEnabled = v);
                  _saveSettings();
                },
              ),
              const Divider(color: AppTheme.cardBorder, height: 1),
              _TappableTile(
                icon: Icons.bedtime_rounded,
                title: 'Bedtime Reminder',
                subtitle: _bedtimeEnabled
                    ? 'Set for ${_bedtime.hour.toString().padLeft(2, '0')}:${_bedtime.minute.toString().padLeft(2, '0')}'
                    : 'Not set',
                trailing: Switch(
                  value: _bedtimeEnabled,
                  onChanged: (v) async {
                    if (v) {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _bedtime,
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.primary,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() {
                          _bedtime = picked;
                          _bedtimeEnabled = true;
                        });
                        await NotificationService.scheduleBedtimeReminder(
                          picked.hour,
                          picked.minute,
                        );
                      }
                    } else {
                      setState(() => _bedtimeEnabled = false);
                      await NotificationService.cancelBedtimeReminder();
                    }
                  },
                ),
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Security
          _SectionHeader('Security'),
          _Card(
            children: [
              _TappableTile(
                icon: Icons.lock_rounded,
                title: 'PIN Protection',
                subtitle: block.hasPin
                    ? 'PIN is set — tap to change'
                    : 'Prevent disabling the blocker',
                onTap: () => _showPinDialog(context, block),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Permissions
          _SectionHeader('Permissions'),
          _Card(
            children: [
              _TappableTile(
                icon: Icons.bar_chart_rounded,
                title: 'Usage Access',
                subtitle: usage.hasPermission ? '✅ Granted' : '⚠️ Not granted',
                trailing: usage.hasPermission
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 20,
                      )
                    : const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                onTap: usage.hasPermission
                    ? null
                    : () {
                        UsageStats.grantUsagePermission();
                      },
              ),
              const Divider(color: AppTheme.cardBorder, height: 1),
              _TappableTile(
                icon: Icons.accessibility_new_rounded,
                title: 'Accessibility Service',
                subtitle: block.accessibilityEnabled
                    ? '✅ Active — app blocking enabled'
                    : '⚠️ Required for app blocking',
                trailing: block.accessibilityEnabled
                    ? const Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 20,
                      )
                    : const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                onTap: block.accessibilityEnabled
                    ? null
                    : () {
                        const platform = MethodChannel(
                            'com.example.social_friction/settings');
                        platform.invokeMethod('openAccessibilitySettings');
                      },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Data
          _SectionHeader('Data'),
          _Card(
            children: [
              _TappableTile(
                icon: Icons.upload_rounded,
                title: 'Export Usage Data',
                subtitle: 'Download as JSON',
                onTap: () => _exportData(context, usage),
              ),
              const Divider(color: AppTheme.cardBorder, height: 1),
              _TappableTile(
                icon: Icons.delete_outline_rounded,
                title: 'Clear All Data',
                subtitle: 'Reset stats, rules and settings',
                onTap: () => _showClearConfirm(context),
                iconColor: AppTheme.danger,
              ),
            ],
          ),
          const SizedBox(height: 40),

          const Center(
            child: Column(
              children: [
                Text(
                  'Social Friction',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'v1.0.0',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showPinDialog(BuildContext context, BlockProvider block) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: Text(
          block.hasPin ? 'Change PIN' : 'Set PIN',
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          obscureText: true,
          autofocus: true,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            letterSpacing: 8,
          ),
          decoration: const InputDecoration(
            hintText: '• • • • • •',
            hintStyle: TextStyle(color: AppTheme.textSecondary),
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          if (block.hasPin)
            TextButton(
              onPressed: () {
                block.clearPin();
                Navigator.pop(context);
              },
              child: const Text(
                'Remove PIN',
                style: TextStyle(color: AppTheme.danger),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.length >= 4) {
                block.setPin(ctrl.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('PIN saved!')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, UsageProvider usage) async {
    final data = {
      'exportDate': DateTime.now().toIso8601String(),
      'todayUsage': usage.todayUsage.map((u) => u.toJson()).toList(),
      'streak': usage.streak,
      'dailyGoalMinutes': usage.dailyGoalMinutes,
    };
    final json = const JsonEncoder.withIndent('  ').convert(data);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exported ${json.length} bytes of data'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Clear All Data?',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'This will reset all stats, block rules, and settings. This cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final void Function(bool) onChanged;
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primary, size: 18),
      ),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _TappableTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const _TappableTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? AppTheme.primary).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor ?? AppTheme.primary, size: 18),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
      trailing:
          trailing ??
          (onTap != null
              ? const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textSecondary,
                )
              : null),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final UsageProvider usage;
  const _GoalCard({required this.usage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Screen Time Goal',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${usage.dailyGoalMinutes}m',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: usage.dailyGoalMinutes.toDouble(),
            min: 30,
            max: 480,
            divisions: 15,
            activeColor: AppTheme.primary,
            inactiveColor: AppTheme.surfaceLight,
            label: '${usage.dailyGoalMinutes}m',
            onChanged: (v) => usage.setDailyGoal(v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                '30m',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Text(
                '8h',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

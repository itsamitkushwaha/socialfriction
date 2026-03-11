import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/block_rule.dart';

class AddLimitScreen extends StatefulWidget {
  final String packageName;
  final String appName;

  const AddLimitScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  State<AddLimitScreen> createState() => _AddLimitScreenState();
}

class _AddLimitScreenState extends State<AddLimitScreen> {
  BlockType _selectedType = BlockType.permanent;
  int _dailyHours = 1;
  int _dailyMinutes = 0;
  int _sessionMinutes = 30;
  TimeOfDay _scheduleStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _scheduleEnd = const TimeOfDay(hour: 7, minute: 0);

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  BlockRule _buildRule() {
    return BlockRule(
      packageName: widget.packageName,
      appName: widget.appName,
      blockType: _selectedType,
      dailyLimitMinutes: _selectedType == BlockType.dailyLimit
          ? _dailyHours * 60 + _dailyMinutes
          : null,
      sessionLimitMinutes:
          _selectedType == BlockType.sessionLimit ? _sessionMinutes : null,
      scheduleStart:
          _selectedType == BlockType.schedule ? _fmtTime(_scheduleStart) : null,
      scheduleEnd:
          _selectedType == BlockType.schedule ? _fmtTime(_scheduleEnd) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Limit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App header card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      widget.appName[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.appName,
                        style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
                    const Text('How do you want to limit usage?',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Block type options
          _TypeOption(
            title: 'Block Permanently',
            subtitle: 'Always blocked, no exceptions',
            icon: Icons.block_rounded,
            selected: _selectedType == BlockType.permanent,
            onTap: () => setState(() => _selectedType = BlockType.permanent),
          ),
          const SizedBox(height: 8),
          _TypeOption(
            title: 'Set a Daily Usage Limit',
            subtitle: 'Block after you reach your daily limit',
            icon: Icons.today_rounded,
            selected: _selectedType == BlockType.dailyLimit,
            onTap: () => setState(() => _selectedType = BlockType.dailyLimit),
          ),
          const SizedBox(height: 8),
          _TypeOption(
            title: 'Block on a Schedule',
            subtitle: 'Block during specific hours',
            icon: Icons.schedule_rounded,
            selected: _selectedType == BlockType.schedule,
            onTap: () => setState(() => _selectedType = BlockType.schedule),
          ),
          const SizedBox(height: 8),
          _TypeOption(
            title: 'Enable Session Limits',
            subtitle: 'Block after N minutes per session',
            icon: Icons.timer_rounded,
            selected: _selectedType == BlockType.sessionLimit,
            onTap: () => setState(() => _selectedType = BlockType.sessionLimit),
          ),

          const SizedBox(height: 20),

          // Type-specific config
          if (_selectedType == BlockType.dailyLimit) _DailyLimitConfig(
            hours: _dailyHours,
            minutes: _dailyMinutes,
            onChanged: (h, m) => setState(() {
              _dailyHours = h;
              _dailyMinutes = m;
            }),
          ),
          if (_selectedType == BlockType.schedule) _ScheduleConfig(
            start: _scheduleStart,
            end: _scheduleEnd,
            onStartChanged: (t) => setState(() => _scheduleStart = t),
            onEndChanged: (t) => setState(() => _scheduleEnd = t),
          ),
          if (_selectedType == BlockType.sessionLimit) _SessionConfig(
            minutes: _sessionMinutes,
            onChanged: (v) => setState(() => _sessionMinutes = v),
          ),

          const SizedBox(height: 24),

          // Save button
          ElevatedButton(
            onPressed: () => Navigator.pop(context, _buildRule()),
            child: const Text('Save Limit'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _DailyLimitConfig extends StatelessWidget {
  final int hours;
  final int minutes;
  final void Function(int, int) onChanged;

  const _DailyLimitConfig(
      {required this.hours, required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What's your daily limit?",
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            children: [
              _NumberPicker(
                  label: 'hrs',
                  value: hours,
                  min: 0,
                  max: 12,
                  onChanged: (v) => onChanged(v, minutes)),
              const SizedBox(width: 16),
              _NumberPicker(
                  label: 'min',
                  value: minutes,
                  min: 0,
                  max: 59,
                  step: 5,
                  onChanged: (v) => onChanged(hours, v)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleConfig extends StatelessWidget {
  final TimeOfDay start;
  final TimeOfDay end;
  final void Function(TimeOfDay) onStartChanged;
  final void Function(TimeOfDay) onEndChanged;

  const _ScheduleConfig({
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Block during hours:',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeButton(
                    label: 'From',
                    time: start,
                    onPick: (t) => onStartChanged(t)),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('→',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 20)),
              ),
              Expanded(
                child: _TimeButton(
                    label: 'To', time: end, onPick: (t) => onEndChanged(t)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final void Function(TimeOfDay) onPick;

  const _TimeButton(
      {required this.label, required this.time, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.dark(primary: AppTheme.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionConfig extends StatelessWidget {
  final int minutes;
  final void Function(int) onChanged;

  const _SessionConfig({required this.minutes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Session limit (minutes):',
              style: TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [5, 10, 15, 20, 30, 45, 60].map((m) {
              final selected = minutes == m;
              return GestureDetector(
                onTap: () => onChanged(m),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary
                        : AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${m}m',
                      style: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _NumberPicker extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final void Function(int) onChanged;

  const _NumberPicker({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.step = 1,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - step) : null,
          icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
        ),
        Column(
          children: [
            Text('$value',
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 12)),
          ],
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + step) : null,
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
        ),
      ],
    );
  }
}

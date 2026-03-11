import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/usage_provider.dart';
import '../services/notification_service.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with SingleTickerProviderStateMixin {
  static const _durations = [15, 25, 30, 45, 60];
  int _selectedMins = 25;
  int _remainingSeconds = 0;
  bool _running = false;
  bool _completed = false;
  Timer? _timer;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _selectedMins * 60;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _completed = false;
      _remainingSeconds = _selectedMins * 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remainingSeconds <= 1) {
        _complete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _running = false);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _completed = false;
      _remainingSeconds = _selectedMins * 60;
    });
  }

  void _complete() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _completed = true;
      _remainingSeconds = 0;
    });
    context.read<UsageProvider>().incrementStreak();
    NotificationService.showFocusComplete(_selectedMins);
  }

  String get _timeDisplay {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final total = _selectedMins * 60;
    if (total == 0) return 0;
    return (_completed) ? 1.0 : 1.0 - (_remainingSeconds / total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Session')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Duration picker (only when not running)
            if (!_running && !_completed) ...[
              const Text(
                'Choose session length',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: _durations.map((d) {
                  final sel = _selectedMins == d;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMins = d;
                        _remainingSeconds = d * 60;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: sel ? AppTheme.primary : AppTheme.cardBorder,
                        ),
                      ),
                      child: Text(
                        '${d}m',
                        style: TextStyle(
                          color: sel ? Colors.white : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
            if (_completed) const SizedBox(height: 20),

            // Ring timer
            Expanded(
              child: Center(
                child: _completed
                    ? _CompletedView(minutes: _selectedMins)
                    : _TimerRing(
                        progress: _progress,
                        timeDisplay: _timeDisplay,
                        running: _running,
                        pulse: _pulse,
                      ),
              ),
            ),

            // Controls
            if (!_completed)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_running)
                    _CircleButton(
                      icon: Icons.pause_rounded,
                      color: AppTheme.accent,
                      onTap: _pause,
                    )
                  else
                    _CircleButton(
                      icon: Icons.play_arrow_rounded,
                      color: AppTheme.primary,
                      onTap: _start,
                    ),
                  if (_running || _remainingSeconds < _selectedMins * 60) ...[
                    const SizedBox(width: 20),
                    _CircleButton(
                      icon: Icons.stop_rounded,
                      color: AppTheme.danger,
                      onTap: _reset,
                      small: true,
                    ),
                  ],
                ],
              ),
            if (_completed)
              ElevatedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Start Another Session'),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final double progress;
  final String timeDisplay;
  final bool running;
  final AnimationController pulse;

  const _TimerRing({
    required this.progress,
    required this.timeDisplay,
    required this.running,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, _) {
        final scale = running ? (1.0 + pulse.value * 0.03) : 1.0;
        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: _FocusRingPainter(progress: progress),
                  size: const Size(240, 240),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeDisplay,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      running ? 'Stay focused!' : 'Ready',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FocusRingPainter extends CustomPainter {
  final double progress;
  _FocusRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const sw = 16.0;

    // Background
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.surfaceLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = sw,
    );

    if (progress > 0) {
      // Gradient progress ring
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        startAngle: -pi / 2,
        endAngle: -pi / 2 + 2 * pi * progress,
        colors: [AppTheme.primary, AppTheme.primaryLight],
      );
      canvas.drawArc(
        rect,
        -pi / 2,
        2 * pi * progress,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_FocusRingPainter old) => old.progress != progress;
}

class _CompletedView extends StatelessWidget {
  final int minutes;
  const _CompletedView({required this.minutes});

  static const _quotes = [
    'Discipline is the bridge between goals and accomplishment.',
    'Small daily improvements lead to stunning results.',
    'Focus is the gateway to all thinking.',
    'The secret of getting ahead is getting started.',
    'Do something today that your future self will thank you for.',
  ];

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[DateTime.now().second % _quotes.length];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                AppTheme.success.withValues(alpha: 0.25),
                AppTheme.surface,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.success,
            size: 80,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Session Complete! 🎉',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You focused for $minutes minutes',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Text(
            '"$quote"',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool small;

  const _CircleButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = small ? 52.0 : 72.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: small ? 24 : 32),
      ),
    );
  }
}

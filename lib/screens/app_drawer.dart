import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';

/// A beautifully styled navigation drawer that slides in from the left
/// on the Dashboard screen. Contains user profile at the top, followed
/// by menu items. Sign Out is pinned to the bottom for safety.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header / Profile Section ──────────────────────────────
            _DrawerHeader(auth: auth),
            const SizedBox(height: 12),

            // ── Menu Items ────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerMenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'My Profile',
                    comingSoon: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const _DrawerMenuItem(
                    icon: Icons.insights_rounded,
                    label: 'Insights',
                    comingSoon: true,
                    onTap: null,
                  ),
                  const _DrawerMenuItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Achievements',
                    comingSoon: true,
                    onTap: null,
                  ),
                  const _DrawerMenuItem(
                    icon: Icons.group_outlined,
                    label: 'Challenges',
                    comingSoon: true,
                    onTap: null,
                  ),
                  const _DrawerMenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Reminders',
                    comingSoon: true,
                    onTap: null,
                  ),
                ],
              ),
            ),

            // ── Divider ───────────────────────────────────────────────
            const Divider(color: AppTheme.cardBorder, height: 1, indent: 20, endIndent: 20),

            // ── Sign Out (Pinned Bottom) ───────────────────────────────
            _SignOutButton(onTap: () async {
              await context.read<AuthProvider>().signOut();
            }),

            // ── Divider + Footer ──────────────────────────────────────
            const Divider(color: AppTheme.cardBorder, height: 1, indent: 20, endIndent: 20),
            _DrawerFooter(),
          ],
        ),
      ),
    );
  }
}

// ─── Header / Profile ──────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final AuthProvider auth;
  const _DrawerHeader({required this.auth});

  @override
  Widget build(BuildContext context) {
    final name = auth.userProfile?['name'] ?? 'Guest';
    final email = auth.user?.email ?? 'No email';
    final streak = auth.userProfile?['streak'] ?? 0;
    final photoUrl = auth.userProfile?['photoUrl'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1040), Color(0xFF0D1420)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Avatar with glow ──
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              // Gradient border ring
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.9),
                      AppTheme.primaryLight.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: photoUrl == null
                        ? const LinearGradient(
                            colors: [Color(0xFF2A1560), Color(0xFF1A2A45)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 34,
                        )
                      : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Name ──
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),

          // ── Email with Online LED ──
          Row(
            children: [
              // Glowing LED dot
              _GlowDot(),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  email,
                  style: TextStyle(
                    color: AppTheme.textSecondary.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Quick Stats ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.cardBorder.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _QuickStat(
                    label: 'Streak',
                    value: '$streak',
                    emoji: '🔥',
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: AppTheme.cardBorder,
                ),
                Expanded(
                  child: _QuickStat(
                    label: 'Blocked',
                    value: '0',
                    emoji: '🚫',
                    color: const Color(0xFFE05555),
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

/// Animated glowing green online indicator dot.
class _GlowDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.success,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.7),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;
  final Color color;
  const _QuickStat({
    required this.label,
    required this.value,
    required this.emoji,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 4),
            Text(emoji, style: const TextStyle(fontSize: 15)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Menu Item ─────────────────────────────────────────────────────────────────

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool comingSoon;
  final VoidCallback? onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.comingSoon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: comingSoon
              ? () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$label — coming soon!'),
                      backgroundColor: AppTheme.surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.cardBorder),
                      ),
                    ),
                  );
                }
              : onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppTheme.primary.withValues(alpha: 0.14),
          highlightColor: AppTheme.primary.withValues(alpha: 0.07),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: comingSoon
                        ? AppTheme.surfaceLight.withValues(alpha: 0.6)
                        : AppTheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: comingSoon
                          ? AppTheme.cardBorder.withValues(alpha: 0.5)
                          : AppTheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: comingSoon
                        ? AppTheme.textSecondary.withValues(alpha: 0.55)
                        : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 14),

                // Label
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: comingSoon
                          ? AppTheme.textSecondary.withValues(alpha: 0.6)
                          : AppTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Glass-style "Soon" pill
                if (comingSoon)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          'Soon',
                          style: TextStyle(
                            color: AppTheme.textSecondary.withValues(alpha: 0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sign Out Button (pinned bottom) ───────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: const Color(0xFFE05555).withValues(alpha: 0.12),
          highlightColor: const Color(0xFFE05555).withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE05555).withValues(alpha: 0.25),
              ),
              color: const Color(0xFFE05555).withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE05555).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE05555).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: Color(0xFFE05555),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Color(0xFFE05555),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Footer ────────────────────────────────────────────────────────────────────

class _DrawerFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/logo.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Social Friction',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'v1.0.0',
                style: TextStyle(
                  color: AppTheme.cardBorder,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

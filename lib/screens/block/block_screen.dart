import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/block_provider.dart';
import '../../models/block_rule.dart';
import 'add_limit_screen.dart';
import 'keyword_block_screen.dart';

class BlockScreen extends StatefulWidget {
  const BlockScreen({super.key});

  @override
  State<BlockScreen> createState() => _BlockScreenState();
}

class _BlockScreenState extends State<BlockScreen> {
  List<AppInfo> _installedApps = [];
  List<AppInfo> _filtered = [];
  bool _loadingApps = true;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await InstalledApps.getInstalledApps(true, true);
    setState(() {
      _installedApps = apps;
      _filtered = _installedApps;
      _loadingApps = false;
    });
  }

  void _filterApps(String query) {
    setState(() {
      _filtered = _installedApps
          .where(
            (a) => a.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Blocker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.key_rounded),
            tooltip: 'Keyword Block',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KeywordBlockScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<BlockProvider>(
        builder: (ctx, block, _) {
          return Column(
            children: [
              // Accessibility service warning
              if (!block.accessibilityEnabled) _AccessibilityBanner(),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: _filterApps,
                  decoration: InputDecoration(
                    hintText: 'Search apps...',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppTheme.textSecondary,
                    ),
                    suffixIcon: _search.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear_rounded,
                              color: AppTheme.textSecondary,
                            ),
                            onPressed: () {
                              _search.clear();
                              _filterApps('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              // Active block count
              if (block.blockedAppCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.block_rounded,
                        color: AppTheme.danger,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${block.blockedAppCount} app${block.blockedAppCount > 1 ? 's' : ''} blocked',
                        style: const TextStyle(
                          color: AppTheme.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // App list
              Expanded(
                child: _loadingApps
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, _) => const Divider(
                          color: AppTheme.cardBorder,
                          height: 1,
                          indent: 70,
                        ),
                        itemBuilder: (ctx, i) {
                          final app = _filtered[i];
                          final pkg = app.packageName;
                          final isBlocked = block.isBlocked(pkg);
                          final rule = block.rules
                              .where((r) => r.packageName == pkg)
                              .firstOrNull;

                          return ListTile(
                            leading: _AppIcon(app: app),
                            title: Text(
                              app.name,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            subtitle: rule != null
                                ? Text(
                                    rule.description,
                                    style: const TextStyle(
                                      color: AppTheme.danger,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing: Switch(
                              value: isBlocked,
                              onChanged: (_) async {
                                if (isBlocked) {
                                  await block.removeRule(pkg);
                                } else {
                                  final result =
                                      await Navigator.push<BlockRule>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddLimitScreen(
                                            packageName: pkg,
                                            appName: app.name,
                                          ),
                                        ),
                                      );
                                  if (result != null) {
                                    await block.addRule(result);
                                  }
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  final AppInfo app;
  const _AppIcon({required this.app});

  @override
  Widget build(BuildContext context) {
    if (app.icon != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(app.icon!, width: 44, height: 44),
      );
    }
    final name = app.name;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          name[0].toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _AccessibilityBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Enable Accessibility Service to block apps',
              style: TextStyle(color: AppTheme.accent, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              const platform = MethodChannel('com.example.social_friction/settings');
              platform.invokeMethod('openAccessibilitySettings');
            },
            child: const Text(
              'Enable',
              style: TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

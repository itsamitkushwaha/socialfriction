import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/block_provider.dart';

class KeywordBlockScreen extends StatefulWidget {
  const KeywordBlockScreen({super.key});

  @override
  State<KeywordBlockScreen> createState() => _KeywordBlockScreenState();
}

class _KeywordBlockScreenState extends State<KeywordBlockScreen> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Keywords')),
      body: Consumer<BlockProvider>(
        builder: (ctx, block, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: 'Add keyword to block...',
                          prefixIcon: Icon(
                            Icons.key_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        onSubmitted: (v) => _addKeyword(v, block),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _addKeyword(_ctrl.text, block),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              if (block.keywords.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.block_rounded,
                          color: AppTheme.textSecondary.withValues(alpha: 0.4),
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No keywords blocked yet',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add keywords to block distracting content',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: block.keywords.length,
                    separatorBuilder: (_, _) =>
                        const Divider(color: AppTheme.cardBorder, height: 1),
                    itemBuilder: (ctx, i) {
                      final kw = block.keywords[i];
                      return ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.danger.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.key_rounded,
                            color: AppTheme.danger,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          kw,
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: AppTheme.danger,
                          ),
                          onPressed: () => block.removeKeyword(kw),
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

  void _addKeyword(String v, BlockProvider block) {
    final kw = v.trim();
    if (kw.isNotEmpty) {
      block.addKeyword(kw);
      _ctrl.clear();
    }
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../../domain/entities/scanned_document.dart';
import '../providers/document_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/themes.dart';
import '../widgets/document_actions_sheet.dart';
import '../widgets/document_card.dart';
import '../widgets/shimmer_grid.dart';
import 'scanner_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListProvider);
    final currentTheme = ref.watch(themeProvider);
    final currentMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocScanner'),
        centerTitle: true,
        actions: [
          PopupMenuButton<AppTheme>(
            icon: Icon(themeIcon(currentTheme)),
            tooltip: 'Change theme',
            onSelected: (t) => ref.read(themeProvider.notifier).setTheme(t),
            itemBuilder: (_) => [
              for (final t in AppTheme.values)
                PopupMenuItem(
                  value: t,
                  child: Row(
                    children: [
                      Icon(themeIcon(t), size: 20,
                        color: t == currentTheme ? Theme.of(context).colorScheme.primary : null),
                      const SizedBox(width: 10),
                      Text(themeLabel(t),
                        style: TextStyle(
                          fontWeight: t == currentTheme ? FontWeight.bold : FontWeight.normal,
                        )),
                      if (t == currentTheme) ...[
                        const Spacer(),
                        Icon(Icons.check, size: 16, color: Theme.of(context).colorScheme.primary),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              currentMode == ThemeMode.dark ? Icons.dark_mode_outlined
                  : currentMode == ThemeMode.light ? Icons.light_mode_outlined
                  : Icons.brightness_auto_outlined,
            ),
            tooltip: 'Theme mode',
            onSelected: (m) => ref.read(themeModeProvider.notifier).setThemeMode(m),
            itemBuilder: (_) => [
              for (final m in ThemeMode.values)
                PopupMenuItem(
                  value: m,
                  child: Row(
                    children: [
                      Icon(_themeModeIcon(m), size: 20),
                      const SizedBox(width: 10),
                      Text(_themeModeLabel(m)),
                      if (m == currentMode) ...[
                        const Spacer(),
                        const Icon(Icons.check, size: 16),
                      ],
                    ],
                  ),
                ),
            ],
          ),
          if (documents.valueOrNull != null && documents.valueOrNull!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _exportPdf(context, ref),
              tooltip: 'Export PDF',
            ),
        ],
      ),
      body: documents.when(
        loading: () => const ShimmerGrid(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text('Something went wrong', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
              ],
            ),
          ),
        ),
        data: (docs) => docs.isEmpty
            ? _EmptyState(onScan: () => _openScanner(context, ref, null))
            : _DocumentGrid(docs: docs),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openScanner(context, ref, null),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Future<void> _openScanner(BuildContext context, WidgetRef ref, String? documentId) async {
    final result = await Navigator.push<Uint8List>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ScannerScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
              child: child,
            ),
      ),
    );
    if (result == null || !context.mounted) return;
    if (documentId != null) {
      ref.read(documentListProvider.notifier).addPageToDocument(documentId, result);
    } else {
      await ref.read(documentListProvider.notifier).scanFromBytes(result);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(documentId != null ? 'Page added' : 'Document saved'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(const SnackBar(content: Text('Generating PDF...')));
      final pdfFile = await ref.read(documentListProvider.notifier).exportToPdf();
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        await Share.shareXFiles([XFile(pdfFile.path)]);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _DocumentGrid extends ConsumerWidget {
  final List<ScannedDocument> docs;

  const _DocumentGrid({required this.docs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.7,
      ),
      itemCount: docs.length,
      itemBuilder: (_, index) {
        final doc = docs[index];
        return DocumentCard(
          document: doc,
          onTap: () => _showActions(context, ref, doc),
        );
      },
    );
  }

  void _showActions(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    showDocumentActionsSheet(
      context,
      doc,
      onRename: () => _rename(context, ref, doc),
      onAddPage: () => _openScanner(context, ref, doc.id),
      onShare: () => _share(doc),
      onDelete: () => _delete(context, ref, doc),
    );
  }

  Future<void> _openScanner(BuildContext context, WidgetRef ref, String? documentId) async {
    final result = await Navigator.push<Uint8List>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const ScannerScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
              child: child,
            ),
      ),
    );
    if (result == null || !context.mounted) return;
    if (documentId != null) {
      await ref.read(documentListProvider.notifier).addPageToDocument(documentId, result);
    } else {
      await ref.read(documentListProvider.notifier).scanFromBytes(result);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(documentId != null ? 'Page added' : 'Document saved'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _share(ScannedDocument doc) {
    Share.shareXFiles([XFile(doc.filePath)]);
  }

  void _rename(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    final controller = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename document'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Document name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            final trimmed = value.trim();
            if (trimmed.isNotEmpty) {
              ref.read(documentListProvider.notifier).rename(doc.id, trimmed);
            }
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final trimmed = controller.text.trim();
              if (trimmed.isNotEmpty) {
                ref.read(documentListProvider.notifier).rename(doc.id, trimmed);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _delete(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    ref.read(documentListProvider.notifier).delete(doc.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${doc.name}" deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ScaffoldMessenger.of(context).clearSnackBars();
          },
        ),
      ),
    );
  }
}

IconData _themeModeIcon(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => Icons.brightness_auto_outlined,
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
  };
}

String _themeModeLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => 'Auto',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;

  const _EmptyState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text('No documents yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Scan your first document\nto get started',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan Document'),
            ),
          ],
        ),
      ),
    );
  }
}

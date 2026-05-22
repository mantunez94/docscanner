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
import 'document_detail_screen.dart';
import 'scanner_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

final batchModeProvider = StateProvider<bool>((ref) => false);

final selectedIdsProvider = StateProvider<Set<String>>((ref) => {});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentsAsync = ref.watch(documentListProvider);
    final currentTheme = ref.watch(themeProvider);
    final currentMode = ref.watch(themeModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final batchMode = ref.watch(batchModeProvider);
    final selectedIds = ref.watch(selectedIdsProvider);

    final documents = documentsAsync.valueOrNull ?? [];

    final filtered = searchQuery.isEmpty
        ? documents
        : documents.where((d) =>
            d.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    final isSearching = searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: batchMode
            ? Text('${selectedIds.length} selected')
            : const Text('DocScanner'),
        centerTitle: true,
        leading: batchMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel selection',
                onPressed: () {
                  ref.read(batchModeProvider.notifier).state = false;
                  ref.read(selectedIdsProvider.notifier).state = {};
                },
              )
            : null,
        actions: [
          if (batchMode && selectedIds.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              onPressed: () => _deleteSelected(context, ref, selectedIds),
              tooltip: 'Delete selected',
            ),
          if (!batchMode) ...[
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
            if (documents.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.checklist),
                onPressed: () => ref.read(batchModeProvider.notifier).state = true,
                tooltip: 'Select documents',
              ),
            if (documents.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _exportPdf(context, ref),
                tooltip: 'Export PDF',
              ),
          ],
        ],
      ),
      body: documentsAsync.when(
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
        data: (_) => documents.isEmpty && searchQuery.isEmpty
            ? _EmptyState(onScan: () => _openScanner(context, ref, null))
            : Column(
                children: [
                  if (documents.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Semantics(
                        label: 'Search documents',
                        child: TextField(
                        onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                        decoration: InputDecoration(
                          hintText: 'Search documents...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  tooltip: 'Clear search',
                                  onPressed: () => ref.read(searchQueryProvider.notifier).state = '',
                                )
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        ),
                        ),
                      ),
                      Expanded(
                      child: filtered.isEmpty && isSearching
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.search_off, size: 64,
                                    color: Theme.of(context).colorScheme.onSurface.withAlpha(80)),
                                  const SizedBox(height: 16),
                                  Text('No documents match',
                                    style: Theme.of(context).textTheme.titleMedium),
                                  const SizedBox(height: 4),
                                  Text('"$searchQuery"',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                            onRefresh: () async {
                              ref.invalidate(documentListProvider);
                            },
                            child: GridView.builder(
                              padding: const EdgeInsets.all(12),
                              physics: const AlwaysScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.7,
                              ),
                              itemCount: filtered.length,
                              itemBuilder: (_, index) {
                                final doc = filtered[index];
                                return DocumentCard(
                                  document: doc,
                                  selected: batchMode ? selectedIds.contains(doc.id) : null,
                                  onTap: () {
                                    if (batchMode) {
                                      final ids = {...ref.read(selectedIdsProvider)};
                                      if (ids.contains(doc.id)) {
                                        ids.remove(doc.id);
                                      } else {
                                        ids.add(doc.id);
                                      }
                                      ref.read(selectedIdsProvider.notifier).state = ids;
                                    } else {
                                      _showActions(context, ref, doc);
                                    }
                                  },
                                  onLongPress: !batchMode
                                      ? () {
                                          ref.read(batchModeProvider.notifier).state = true;
                                          ref.read(selectedIdsProvider.notifier).state = {doc.id};
                                        }
                                      : null,
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
      ),
      floatingActionButton: batchMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openScanner(context, ref, null),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan'),
              tooltip: 'Scan a document',
            ),
    );
  }

  void _deleteSelected(BuildContext context, WidgetRef ref, Set<String> ids) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete documents'),
        content: Text('Delete ${ids.length} document${ids.length > 1 ? 's' : ''}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              for (final id in ids) {
                ref.read(documentListProvider.notifier).delete(id);
              }
              ref.read(batchModeProvider.notifier).state = false;
              ref.read(selectedIdsProvider.notifier).state = {};
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${ids.length} document${ids.length > 1 ? 's' : ''} deleted')),
                );
              }
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }

  static Future<void> _openScanner(BuildContext context, WidgetRef ref, String? documentId) async {
    String? docId = documentId;
    var pagesScanned = 0;

    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ScannerScreen(
          batchMode: true,
          onPageScanned: (bytes) async {
            if (docId == null) {
              await ref.read(documentListProvider.notifier).scanFromBytes(bytes);
              final docs = ref.read(documentListProvider).valueOrNull ?? [];
              if (docs.isNotEmpty) docId = docs.last.id;
            } else {
              await ref.read(documentListProvider.notifier).addPageToDocument(docId!, bytes);
            }
            pagesScanned++;
          },
        ),
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
    if (!context.mounted) return;
    ref.invalidate(documentListProvider);
    final scanned = result == true || pagesScanned > 0;
    if (scanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(documentId != null ? 'Pages added' : 'Document saved'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showActions(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    showDocumentActionsSheet(
      context,
      doc,
      onRename: () => _rename(context, ref, doc),
      onAddPage: () => _openScanner(context, ref, doc.id),
      onShare: () => _share(doc),
      onDelete: () => _deleteOne(context, ref, doc),
      onViewPages: () => _openDetail(context, ref, doc),
      onReorderPages: () => _openDetail(context, ref, doc, reorderMode: true),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref, ScannedDocument doc, {bool reorderMode = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentDetailScreen(document: doc, initialReorderMode: reorderMode),
      ),
    );
  }

  void _share(ScannedDocument doc) {
    final path = doc.pdfPath ?? doc.filePath;
    Share.shareXFiles([XFile(path)]);
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

  void _deleteOne(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document'),
        content: Text('Are you sure you want to delete "${doc.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(documentListProvider.notifier).delete(doc.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${doc.name}" deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
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
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export PDF. Please try again.')),
        );
      }
    }
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

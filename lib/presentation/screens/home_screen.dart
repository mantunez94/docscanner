import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:docscanner/l10n/app_localizations.dart';
import '../../domain/entities/scanned_document.dart';
import '../providers/document_provider.dart';
import '../providers/document_admin_provider.dart';
import '../providers/document_export_provider.dart';
import '../providers/document_page_provider.dart';
import '../providers/document_scan_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/themes.dart';
import '../services/ad_service.dart';
import 'help_screen.dart';
import '../widgets/document_actions_sheet.dart';
import '../widgets/document_card.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/post_save_ad_card.dart';
import '../widgets/responsive_utils.dart';
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
    final l10n = AppLocalizations.of(context)!;
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
            ? Text(selectedIds.isEmpty ? l10n.selectDocuments : l10n.nSelected(selectedIds.length))
            : Text(l10n.appTitle),
        centerTitle: true,
        leading: batchMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.cancelSelection,
                onPressed: () {
                  ref.read(batchModeProvider.notifier).state = false;
                  ref.read(selectedIdsProvider.notifier).state = {};
                },
              )
            : null,
        actions: [
          if (batchMode && selectedIds.isNotEmpty)
            IconButton(
              icon: Icon(deleteIcon(currentTheme),
                  color: Theme.of(context).colorScheme.error),
              onPressed: () => _deleteSelected(context, ref, selectedIds),
              tooltip: l10n.deleteSelected,
            ),
          if (batchMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: selectedIds.length == filtered.length
                  ? l10n.deselectAll
                  : l10n.selectAll,
              onPressed: () {
                if (selectedIds.length == filtered.length) {
                  ref.read(selectedIdsProvider.notifier).state = {};
                } else {
                  ref.read(selectedIdsProvider.notifier).state =
                      filtered.map((d) => d.id).toSet();
                }
              },
            ),
          if (!batchMode) ...[
            PopupMenuButton<AppTheme>(
              icon: Icon(themeIcon(currentTheme)),
              tooltip: l10n.changeTheme,
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
              tooltip: l10n.themeMode,
              onSelected: (m) => ref.read(themeModeProvider.notifier).setThemeMode(m),
              itemBuilder: (_) => [
                for (final m in ThemeMode.values)
                  PopupMenuItem(
                    value: m,
                    child: Row(
                      children: [
                        Icon(_themeModeIcon(m), size: 20),
                        const SizedBox(width: 10),
                        Text(_themeModeLabel(m, context)),
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
                icon: Icon(checklistIcon(currentTheme)),
                onPressed: () => ref.read(batchModeProvider.notifier).state = true,
                tooltip: l10n.selectDocuments,
              ),
            if (documents.isNotEmpty)
              IconButton(
                icon: Icon(pdfIcon(currentTheme)),
                onPressed: () => _exportPdf(context, ref),
                tooltip: l10n.exportPdf,
              ),
              IconButton(
                icon: Icon(infoIcon(currentTheme)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen())),
                tooltip: l10n.about,
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
                Text(l10n.somethingWentWrong, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withAlpha(150))),
              ],
            ),
          ),
        ),
        data: (_) {
          if (documents.isEmpty && searchQuery.isEmpty) {
            return _EmptyState(currentTheme: currentTheme, onScan: () => _openScanner(context, ref, null));
          }
          return Column(
            children: [
              if (documents.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Semantics(
                    label: l10n.searchDocuments,
                    child: TextField(
                    onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                    decoration: InputDecoration(
                      hintText: l10n.searchDocuments,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              tooltip: l10n.clearSearch,
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
              if (ref.watch(showPostSaveAdProvider))
                PostSaveAdCard(
                  adService: ref.watch(adServiceProvider),
                  onDismissed: () => ref.read(showPostSaveAdProvider.notifier).state = false,
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
                            Text(l10n.noDocumentsMatch,
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
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.all(12),
                            sliver: SliverGrid(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: responsiveCrossAxisCount(context),
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.7,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
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
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: BannerAdWidget(
        adService: ref.watch(adServiceProvider),
        visible: ref.watch(showAdBannerProvider),
        onDismissed: () => ref.read(showAdBannerProvider.notifier).state = false,
      ),
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: batchMode
            ? const SizedBox.shrink(key: ValueKey('batch'))
            : FloatingActionButton.extended(
                key: const ValueKey('scan'),
                onPressed: () => _openScanner(context, ref, null),
                icon: Icon(scanIcon(currentTheme)),
                label: Text(l10n.scan),
                tooltip: l10n.scanADocument,
              ),
      ),
    );
  }

  void _deleteSelected(BuildContext context, WidgetRef ref, Set<String> ids) {
    final docs = ref.read(documentListProvider).valueOrNull ?? [];
    final deletedDocs = docs.where((d) => ids.contains(d.id)).toList();

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Theme.of(ctx).colorScheme.error, size: 24),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.deleteDocuments)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(l10n.deleteNDocuments(ids.length)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                for (final id in ids) {
                  ref.read(documentAdminProvider).delete(id);
                }
                ref.read(batchModeProvider.notifier).state = false;
                ref.read(selectedIdsProvider.notifier).state = {};
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.nDocumentsDeleted(ids.length)),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.undo,
                        onPressed: () {
                          for (final doc in deletedDocs) {
                            ref.read(documentAdminProvider).restore(doc);
                          }
                        },
                      ),
                    ),
                  );
                }
              },
              child: Text(l10n.delete, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _openScanner(BuildContext context, WidgetRef ref, String? documentId) async {
    final existingNames = ref.read(documentListProvider)
        .valueOrNull
        ?.map((d) => d.name)
        .toSet() ?? {};
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => ScannerScreen(
          existingNames: existingNames,
          onPagesSaved: (pages, name) async {
            if (documentId == null) {
              await ref.read(documentScanProvider).scanFromMultipleBytes(pages, name);
            } else {
              await ref.read(documentPageProvider).addMultiplePagesToDocument(documentId, pages);
            }
          },
        ),
        transitionsBuilder: (_, animation, _, child) =>
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
    ref.read(showAdBannerProvider.notifier).state = true;
    ref.read(showPostSaveAdProvider.notifier).state = true;
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(documentId != null ? AppLocalizations.of(context)!.pagesAdded : AppLocalizations.of(context)!.documentSaved),
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

  Future<void> _share(ScannedDocument doc) async {
    final path = doc.pdfPath ?? doc.filePath;
    final isPdf = doc.pdfPath != null;
    final ext = isPdf ? '.pdf' : '.jpg';
    final safeName = doc.name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final temp = await _tempFile(safeName, ext, path);
    await Share.shareXFiles([XFile(temp.path)]);
  }

  Future<File> _tempFile(String baseName, String ext, String sourcePath) async {
    final dir = await getTemporaryDirectory();
    var file = File('${dir.path}/$baseName$ext');
    var counter = 1;
    while (await file.exists()) {
      file = File('${dir.path}/$baseName ($counter)$ext');
      counter++;
    }
    await File(sourcePath).copy(file.path);
    return file;
  }

  void _rename(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    final controller = TextEditingController(text: doc.name);
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.renameDocument),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.documentName,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              final trimmed = value.trim();
              if (trimmed.isNotEmpty) {
                ref.read(documentAdminProvider).rename(doc.id, trimmed);
              }
              Navigator.pop(ctx);
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty) {
                  ref.read(documentAdminProvider).rename(doc.id, trimmed);
                }
                Navigator.pop(ctx);
              },
              child: Text(l10n.rename),
            ),
          ],
        );
      },
    );
  }

  void _deleteOne(BuildContext context, WidgetRef ref, ScannedDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return AlertDialog(
          title: Text(l10n.deleteDocument),
          content: SingleChildScrollView(
            child: Text(l10n.deleteDocumentConfirm(doc.name)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(documentAdminProvider).delete(doc.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.nameDeleted(doc.name)),
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: AppLocalizations.of(context)!.undo,
                      onPressed: () => ref.read(documentAdminProvider).restore(doc),
                    ),
                  ),
                );
              },
              child: Text(l10n.delete, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.generatingPdf)));
      final pdfFile = await ref.read(documentExportProvider).exportToPdf();
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        final temp = await _tempFile('All documents', '.pdf', pdfFile.path);
        await Share.shareXFiles([XFile(temp.path)]);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failedExportPdf)),
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

String _themeModeLabel(ThemeMode mode, BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return switch (mode) {
    ThemeMode.system => l10n.auto,
    ThemeMode.light => l10n.light,
    ThemeMode.dark => l10n.dark,
  };
}

class _EmptyState extends StatelessWidget {
  final AppTheme currentTheme;
  final VoidCallback onScan;

  const _EmptyState({required this.currentTheme, required this.onScan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
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
                descriptionIcon(currentTheme),
                size: 64,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(l10n.noDocumentsYet, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.scanFirstDocument,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(150)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.camera_alt),
              label: Text(l10n.scanDocument),
            ),
          ],
        ),
      ),
    );
  }
}

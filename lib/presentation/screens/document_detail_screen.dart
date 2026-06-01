import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import '../../domain/entities/scanned_document.dart';
import '../providers/document_admin_provider.dart';
import '../providers/document_page_provider.dart';
import '../providers/document_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/themes.dart';
import '../widgets/responsive_utils.dart';
import 'preview_screen.dart';
import 'scanner_screen.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final ScannedDocument document;
  final bool initialReorderMode;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    this.initialReorderMode = false,
  });

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _batchMode = false;
  final Set<int> _selectedIndices = {};
  bool _reorderMode = false;
  late List<String> _reorderablePages;

  @override
  void initState() {
    super.initState();
    _selectedIndices.clear();
    _batchMode = false;
    _reorderMode = widget.initialReorderMode;
    _reorderablePages = List.from(widget.document.pages);
  }

  Future<void> _saveReorder() async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(documentPageProvider).reorderPages(
      widget.document.id,
      _reorderablePages,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.pagesReordered)),
    );
    setState(() => _reorderMode = false);
  }

  void _cancelReorder() {
    final l10n = AppLocalizations.of(context)!;
    if (listEquals(_reorderablePages, widget.document.pages)) {
      setState(() {
        _reorderablePages = List.from(widget.document.pages);
        _reorderMode = false;
      });
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardChanges),
        content: Text(l10n.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _reorderablePages = List.from(widget.document.pages);
                _reorderMode = false;
              });
            },
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context)!;
    final pages = _reorderMode ? _reorderablePages : widget.document.pages;
    final hasSelection = _selectedIndices.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_reorderMode ? l10n.reorderPages : widget.document.name),
        actions: [
          if (_reorderMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: l10n.done,
              onPressed: _saveReorder,
            ),
          ] else ...[
            if (pages.length > 1 && !_batchMode)
              IconButton(
                icon: Icon(checklistIcon(appTheme)),
                tooltip: l10n.selectPages,
                onPressed: () => setState(() => _batchMode = true),
              ),
            if (_batchMode)
              IconButton(
                icon: Icon(deleteIcon(appTheme), color: theme.colorScheme.error),
                tooltip: l10n.deleteSelected,
                onPressed: hasSelection ? _deleteSelected : null,
              ),
          ],
        ],
        leading: _batchMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.cancelSelection,
                onPressed: () => setState(() {
                  _batchMode = false;
                  _selectedIndices.clear();
                }),
              )
            : _reorderMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.cancelReorder,
                    onPressed: _cancelReorder,
                  )
                : null,
      ),
      body: pages.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(photoLibraryIcon(appTheme), size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text(l10n.noPages, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(l10n.noPagesBody, style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150))),
                ],
              ),
            )
          : _reorderMode
              ? _buildReorderableList(pages, theme)
              : _buildGridView(pages, theme),
      floatingActionButton: !_reorderMode && !_batchMode
          ? FloatingActionButton(
              onPressed: () => _openScanner(context),
              tooltip: l10n.addPage,
              child: Icon(addPhotoIcon(appTheme)),
            )
          : null,
    );
  }

  Widget _buildGridView(List<String> pages, ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(documentListProvider);
      },
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: responsiveCrossAxisCount(context),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.7,
        ),
        itemCount: pages.length,
        itemBuilder: (_, index) => _buildPageCard(pages, index, theme),
      ),
    );
  }

  Future<void> _openPageForEditing(int index, String path) async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(imagePath: path),
      ),
    );
    if (!context.mounted || result == null) return;
    await File(path).writeAsBytes(result);
    await ref.read(documentPageProvider).reorderPages(
      widget.document.id,
      List<String>.from(widget.document.pages),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => ScannerScreen(
          onPagesSaved: (pages, _) async {
            await ref.read(documentPageProvider).addMultiplePagesToDocument(
              widget.document.id,
              pages,
            );
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
  }

  Widget _buildPageCard(List<String> pages, int index, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    final path = pages[index];
    final selected = _selectedIndices.contains(index);
    return GestureDetector(
      onTap: () {
        if (_batchMode) {
          setState(() {
            if (selected) {
              _selectedIndices.remove(index);
            } else {
              _selectedIndices.add(index);
            }
          });
        } else {
          _openPageForEditing(index, path);
        }
      },
      onLongPress: !_batchMode
          ? () => setState(() {
                _batchMode = true;
                _selectedIndices.add(index);
              })
          : null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(path),
              cacheWidth: 400,
              fit: BoxFit.cover,
              semanticLabel: '${l10n.pageN(index + 1)} thumbnail',
              errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 48),
            ),
            if (_batchMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface.withAlpha(180),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? theme.colorScheme.onPrimary : null,
                    size: 24,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                color: Colors.black54,
                child: Text(
                  l10n.pageN(index + 1),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableList(List<String> pages, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: pages.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _reorderablePages.removeAt(oldIndex);
          _reorderablePages.insert(newIndex, item);
        });
      },
      itemBuilder: (_, index) {
        final path = pages[index];
        return Card(
          key: ValueKey(path),
          margin: const EdgeInsets.only(bottom: 8),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Semantics(
                  label: 'Drag to reorder ${l10n.pageN(index + 1)}',
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.drag_handle, color: theme.colorScheme.onSurface.withAlpha(120)),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 60,
                  height: 60,
              child: Image.file(File(path), cacheWidth: 120, fit: BoxFit.cover,
                  semanticLabel: '${l10n.pageN(index + 1)} thumbnail',
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Text(l10n.pageN(index + 1),
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }

  void _deleteSelected() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final count = _selectedIndices.length;
    if (count == 0 || count >= widget.document.pages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count >= widget.document.pages.length
              ? l10n.cannotDeleteAllPages
              : l10n.noPagesSelected),
          duration: const Duration(seconds: 4),
          action: count >= widget.document.pages.length
              ? SnackBarAction(
                  label: l10n.deleteDocument,
                  onPressed: () {
                    ref.read(documentAdminProvider).delete(widget.document.id);
                    Navigator.pop(context);
                  },
                )
              : null,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePages),
        content: SingleChildScrollView(
          child: Text(l10n.deleteNPages(count)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final pathsToRemove = _selectedIndices
                  .map((i) => widget.document.pages[i])
                  .toList();

              for (final path in pathsToRemove) {
                try {
                  await ref
                      .read(documentPageProvider)
                      .removePage(widget.document.id, path);
                } catch (e) {
                  debugPrint('Failed to remove page $path: $e');
                }
              }

              if (!context.mounted) return;
              setState(() {
                _batchMode = false;
                _selectedIndices.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.nPagesDeleted(count))),
              );
            },
            child: Text(l10n.delete, style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scanned_document.dart';
import '../providers/document_provider.dart';
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
    await ref.read(documentListProvider.notifier).reorderPages(
      widget.document.id,
      _reorderablePages,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pages reordered')),
    );
    setState(() => _reorderMode = false);
  }

  void _cancelReorder() {
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
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes to the page order.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _reorderablePages = List.from(widget.document.pages);
                _reorderMode = false;
              });
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = _reorderMode ? _reorderablePages : widget.document.pages;
    final hasSelection = _selectedIndices.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_reorderMode ? 'Reorder pages' : widget.document.name),
        actions: [
          if (_reorderMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Done',
              onPressed: _saveReorder,
            ),
          ] else ...[
            if (pages.length > 1 && !_batchMode)
              IconButton(
                icon: const Icon(Icons.checklist),
                tooltip: 'Select pages',
                onPressed: () => setState(() => _batchMode = true),
              ),
            if (_batchMode)
              IconButton(
                icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                tooltip: 'Delete selected',
                onPressed: hasSelection ? _deleteSelected : null,
              ),
          ],
        ],
        leading: _batchMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancel selection',
                onPressed: () => setState(() {
                  _batchMode = false;
                  _selectedIndices.clear();
                }),
              )
            : _reorderMode
                ? IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel reorder',
                    onPressed: _cancelReorder,
                  )
                : null,
      ),
      body: pages.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64,
                    color: theme.colorScheme.onSurface.withAlpha(80)),
                  const SizedBox(height: 16),
                  Text('No pages', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('This document has no pages', style: theme.textTheme.bodyMedium?.copyWith(
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
              tooltip: 'Add page',
              child: const Icon(Icons.add_a_photo_outlined),
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
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
    await ref.read(documentListProvider.notifier).reorderPages(
      widget.document.id,
      List<String>.from(widget.document.pages),
    );
  }

  Future<void> _openScanner(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ScannerScreen(
          batchMode: true,
          onPageScanned: (bytes) async {
            await ref.read(documentListProvider.notifier).addPageToDocument(
              widget.document.id,
              bytes,
            );
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
  }

  Widget _buildPageCard(List<String> pages, int index, ThemeData theme) {
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
              fit: BoxFit.cover,
              semanticLabel: 'Page ${index + 1} thumbnail',
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
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
                  'Page ${index + 1}',
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
                  label: 'Drag to reorder page ${index + 1}',
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
              child: Image.file(File(path), fit: BoxFit.cover,
                  semanticLabel: 'Page ${index + 1} thumbnail',
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Text('Page ${index + 1}',
                  style: theme.textTheme.bodyMedium),
            ],
          ),
        );
      },
    );
  }

  void _deleteSelected() {
    final theme = Theme.of(context);
    final count = _selectedIndices.length;
    if (count == 0 || count >= widget.document.pages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count >= widget.document.pages.length
              ? 'Cannot delete all pages. Delete the document instead.'
              : 'No pages selected'),
          duration: const Duration(seconds: 4),
          action: count >= widget.document.pages.length
              ? SnackBarAction(
                  label: 'Delete document',
                  onPressed: () {
                    ref.read(documentListProvider.notifier).delete(widget.document.id);
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
        title: const Text('Delete pages'),
        content: Text('Delete $count page${count > 1 ? 's' : ''}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
                      .read(documentListProvider.notifier)
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
                SnackBar(content: Text('$count page${count > 1 ? 's' : ''} deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

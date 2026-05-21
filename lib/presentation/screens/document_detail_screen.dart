import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scanned_document.dart';
import '../providers/document_provider.dart';

class DocumentDetailScreen extends ConsumerStatefulWidget {
  final ScannedDocument document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  ConsumerState<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends ConsumerState<DocumentDetailScreen> {
  bool _batchMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _selectedIndices.clear();
    _batchMode = false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pages = widget.document.pages;
    final hasSelection = _selectedIndices.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.document.name),
        actions: [
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
        leading: _batchMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _batchMode = false;
                  _selectedIndices.clear();
                }),
              )
            : null,
      ),
      body: pages.isEmpty
          ? Center(
              child: Text('No pages', style: theme.textTheme.bodyMedium),
            )
          : RefreshIndicator(
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
                itemBuilder: (_, index) {
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
                          if (File(path).existsSync())
                            Image.file(
                              File(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                            )
                          else
                            const Icon(Icons.broken_image, size: 48),
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
                },
              ),
            ),
    );
  }

  void _deleteSelected() {
    final count = _selectedIndices.length;
    if (count == 0 || count >= widget.document.pages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count >= widget.document.pages.length
              ? 'Cannot delete all pages. Delete the document instead.'
              : 'No pages selected'),
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
                } catch (_) {}
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
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'preview_screen.dart';

class MultiPageReviewScreen extends StatefulWidget {
  final List<String> pagePaths;
  final bool colorMode;
  final Future<void> Function(List<String> paths, String name) onSave;
  final Set<String> existingNames;

  const MultiPageReviewScreen({
    super.key,
    required this.pagePaths,
    required this.colorMode,
    required this.onSave,
    this.existingNames = const {},
  });

  @override
  State<MultiPageReviewScreen> createState() => _MultiPageReviewScreenState();
}

class _MultiPageReviewScreenState extends State<MultiPageReviewScreen> {
  late List<_PageItem> _pages;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pages = widget.pagePaths
        .map((path) => _PageItem(path: path))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${_pages.length} page${_pages.length == 1 ? '' : 's'})'),
        actions: [
          if (_pages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete all',
              onPressed: _confirmDeleteAll,
            ),
        ],
      ),
      body: _pages.isEmpty
          ? const Center(child: Text('No pages'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _pages.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final item = _pages.removeAt(oldIndex);
                  _pages.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final page = _pages[index];
                return _PageTile(
                  key: ValueKey(page.path),
                  index: index,
                  path: page.path,
                  onTap: () => _editPage(index),
                  onDelete: () => _deletePage(index),
                );
              },
            ),
      bottomNavigationBar: _pages.isNotEmpty
          ? Container(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: SafeArea(
                top: false,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Saving...' : 'Save as document'),
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _editPage(int index) async {
    final result = await Navigator.push<Object>(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          imagePath: _pages[index].path,
          initialColorMode: widget.colorMode,
        ),
      ),
    );
    if (!context.mounted) return;
    if (result is Uint8List) {
      final dir = Directory.systemTemp;
      final path = '${dir.path}/multipage_edit_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(path).writeAsBytes(result);
      setState(() => _pages[index] = _PageItem(path: path));
    }
  }

  void _deletePage(int index) {
    setState(() => _pages.removeAt(index));
  }

  Future<void> _confirmDeleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete all pages?'),
        content: const Text('All captured pages will be discarded.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      setState(() => _pages.clear());
    }
  }

  String _defaultName() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _save() async {
    final nameController = TextEditingController(text: _defaultName());
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => _SaveAsDialog(
        controller: nameController,
        defaultName: _defaultName(),
        existingNames: widget.existingNames,
      ),
    );
    if (name == null || !context.mounted) return;

    setState(() => _saving = true);
    try {
      final paths = _pages.map((p) => p.path).toList();
      await widget.onSave(paths, name);
      if (context.mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Save failed: $e');
      if (context.mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save document. Please try again.')),
        );
      }
    }
  }
}

class _SaveAsDialog extends StatefulWidget {
  final TextEditingController controller;
  final String defaultName;
  final Set<String> existingNames;

  const _SaveAsDialog({
    required this.controller,
    required this.defaultName,
    required this.existingNames,
  });

  @override
  State<_SaveAsDialog> createState() => _SaveAsDialogState();
}

class _SaveAsDialogState extends State<_SaveAsDialog> {
  String? _error;

  String _sanitize(String value) => value.trim().isEmpty ? widget.defaultName : value.trim();

  void _submit() {
    final name = _sanitize(widget.controller.text);
    if (widget.existingNames.contains(name)) {
      setState(() => _error = 'A document named "$name" already exists.');
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Save as'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Document name',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PageItem {
  final String path;
  const _PageItem({required this.path});
}

class _PageTile extends StatelessWidget {
  final int index;
  final String path;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PageTile({
    super.key,
    required this.index,
    required this.path,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey(path),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Image.file(
            File(path),
            width: 48,
            height: 64,
            fit: BoxFit.cover,
            cacheWidth: 120,
          ),
        ),
        title: Text('Page ${index + 1}'),
        subtitle: Text('${(File(path).lengthSync() / 1024).round()} KB'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit page',
              onPressed: onTap,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              tooltip: 'Delete page',
              onPressed: onDelete,
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import '../../domain/entities/scanned_document.dart';
import '../providers/document_provider.dart';
import '../widgets/document_card.dart';
import 'scanner_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocScanner'),
        centerTitle: true,
        actions: [
          if (documents.valueOrNull != null && documents.valueOrNull!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => _exportPdf(context, ref),
              tooltip: 'Export PDF',
            ),
        ],
      ),
      body: documents.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) => docs.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, size: 80, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No documents yet', style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Tap + to scan your first document'),
                  ],
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.7,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  return DocumentCard(
                    document: doc,
                    onDelete: () => _deleteDocument(ref, doc),
                    onShare: () => _shareDocument(doc),
                    onRename: () => _renameDocument(context, ref, doc),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openScanner(context, ref),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }

  Future<void> _openScanner(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (result != null && context.mounted) {
      ref.read(documentListProvider.notifier).scanFromBytes(result);
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

  void _shareDocument(ScannedDocument doc) {
    Share.shareXFiles([XFile(doc.filePath)]);
  }

  void _renameDocument(BuildContext context, WidgetRef ref, ScannedDocument doc) {
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

  void _deleteDocument(WidgetRef ref, ScannedDocument doc) {
    showDialog(
      context: ref.context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(documentListProvider.notifier).delete(doc.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

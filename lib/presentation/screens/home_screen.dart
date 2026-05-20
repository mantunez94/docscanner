import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

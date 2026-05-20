import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/scanned_document.dart';

class DocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onRename;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onDelete,
    required this.onShare,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onLongPress: onDelete,
              child: Image.file(
                File(document.thumbnailPath),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: onRename,
                      child: const Icon(Icons.edit, size: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${document.pageCount} page${document.pageCount > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: onShare,
                      child: const Icon(Icons.share, size: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

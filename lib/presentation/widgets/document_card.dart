import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/scanned_document.dart';

class DocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onDelete,
    required this.onShare,
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
                Text(
                  DateFormat('MMM d, yyyy').format(document.createdAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import '../../domain/entities/scanned_document.dart';
import '../providers/document_admin_provider.dart';
import '../providers/document_provider.dart';
import '../providers/search_batch_providers.dart';
import '../services/undo_service.dart';

void showDeleteSelectedDialog(
  BuildContext context,
  WidgetRef ref,
  Set<String> ids,
) {
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
              ref.read(undoActionProvider.notifier).state = UndoAction(
                label: l10n.nDocumentsDeleted(ids.length),
                onUndo: () {
                  for (final doc in deletedDocs) {
                    ref.read(documentAdminProvider).restore(doc);
                  }
                },
              );
              if (context.mounted) {
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  SnackBar(
                    duration: const Duration(seconds: 3),
                    dismissDirection: DismissDirection.horizontal,
                    content: Row(
                      children: [
                        Expanded(
                          child: Text(l10n.nDocumentsDeleted(ids.length)),
                        ),
                        GestureDetector(
                          onTap: () {
                            final action = ref.read(undoActionProvider);
                            if (action != null) {
                              action.onUndo();
                              ref.read(undoActionProvider.notifier).state = null;
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              l10n.undo,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
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

void showDeleteOneDialog(
  BuildContext context,
  WidgetRef ref,
  ScannedDocument doc,
) {
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
              ref.read(undoActionProvider.notifier).state = UndoAction(
                label: l10n.nameDeleted(doc.name),
                onUndo: () => ref.read(documentAdminProvider).restore(doc),
              );
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  duration: const Duration(seconds: 3),
                  dismissDirection: DismissDirection.horizontal,
                  content: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.nameDeleted(doc.name)),
                      ),
                      GestureDetector(
                        onTap: () {
                          final action = ref.read(undoActionProvider);
                          if (action != null) {
                            action.onUndo();
                            ref.read(undoActionProvider.notifier).state = null;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            l10n.undo,
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
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

void showRenameDialog(
  BuildContext context,
  WidgetRef ref,
  ScannedDocument doc,
) {
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

import 'package:flutter/material.dart';
import '../../domain/entities/scanned_document.dart';

Future<void> showDocumentActionsSheet(
  BuildContext context,
  ScannedDocument doc, {
  required VoidCallback onRename,
  required VoidCallback onAddPage,
  required VoidCallback onShare,
  required VoidCallback onDelete,
  VoidCallback? onViewPages,
  VoidCallback? onReorderPages,
}) {
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              doc.name,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: Icons.edit_outlined,
            label: 'Rename',
            onTap: () { Navigator.pop(ctx); onRename(); },
          ),
          _ActionTile(
            icon: Icons.add_circle_outline,
            label: 'Add page',
            onTap: () { Navigator.pop(ctx); onAddPage(); },
          ),
          if (onViewPages != null)
            _ActionTile(
              icon: Icons.pages_outlined,
              label: 'View pages (${doc.pageCount})',
              onTap: () { Navigator.pop(ctx); onViewPages(); },
            ),
          if (onReorderPages != null && doc.pages.length > 1)
            _ActionTile(
              icon: Icons.swap_vert_outlined,
              label: 'Reorder pages',
              onTap: () { Navigator.pop(ctx); onReorderPages(); },
            ),
          _ActionTile(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () { Navigator.pop(ctx); onShare(); },
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete',
            isDestructive: true,
            onTap: () { Navigator.pop(ctx); onDelete(); },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: color != null ? TextStyle(color: color) : null),
      onTap: onTap,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scanned_document.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../theme/themes.dart';

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
  final l10n = AppLocalizations.of(context)!;
  final appTheme = ProviderScope.containerOf(context).read(themeProvider);
  return showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Icon(descriptionIcon(appTheme), size: 32,
              color: Theme.of(context).colorScheme.primary),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              doc.name,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(height: 1),
          _ActionTile(
            icon: editIcon(appTheme),
            label: l10n.renameLabel,
            onTap: () { Navigator.pop(ctx); onRename(); },
          ),
          _ActionTile(
            icon: addIcon(appTheme),
            label: l10n.addPage,
            onTap: () { Navigator.pop(ctx); onAddPage(); },
          ),
          if (onViewPages != null)
            _ActionTile(
              icon: pagesIcon(appTheme),
              label: l10n.viewPages(doc.pageCount),
              onTap: () { Navigator.pop(ctx); onViewPages(); },
            ),
          if (onReorderPages != null && doc.pages.length > 1)
            _ActionTile(
              icon: reorderIcon(appTheme),
              label: l10n.reorderPages,
              onTap: () { Navigator.pop(ctx); onReorderPages(); },
            ),
          _ActionTile(
            icon: shareIcon(appTheme),
            label: l10n.share,
            onTap: () { Navigator.pop(ctx); onShare(); },
          ),
          _ActionTile(
            icon: deleteIcon(appTheme),
            label: l10n.delete,
            isDestructive: true,
            onTap: () { Navigator.pop(ctx); onDelete(); },
          ),
          const SizedBox(height: 8),
        ],
      ),
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

import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/scanned_document.dart';

class DocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final bool? selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const DocumentCard({
    super.key,
    required this.document,
    this.selected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = selected == true;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 2,
      shadowColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(document.thumbnailPath),
                    cacheWidth: 400,
                    fit: BoxFit.cover,
                    semanticLabel: 'Thumbnail of ${document.name}',
                    errorBuilder: (_, _, _) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, size: 32, color: theme.colorScheme.onSurface.withAlpha(100)),
                          const SizedBox(height: 4),
                          Text('Tap to reload', style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(80))),
                        ],
                      ),
                    ),
                  ),
                  if (selected != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primary : Colors.black38,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSelected ? Icons.check_circle : Icons.circle_outlined,
                          size: 24,
                          color: isSelected ? theme.colorScheme.onPrimary : Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.description, size: 12, color: theme.colorScheme.onSurface.withAlpha(120)),
                      const SizedBox(width: 4),
                      Text(
                        '${document.pageCount} page${document.pageCount > 1 ? 's' : ''}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(150),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

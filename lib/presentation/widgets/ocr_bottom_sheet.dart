import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import '../../domain/entities/ocr_result.dart';

class OcrBottomSheet extends StatelessWidget {
  final OcrResult result;

  const OcrBottomSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.extractedText, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(l10n.nTextBlocksFound(result.blocks.length),
                  style: Theme.of(context).textTheme.bodySmall),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    SelectableText(result.text,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: result.text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.textCopiedToClipboard)),
                      );
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(l10n.copyToClipboard),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

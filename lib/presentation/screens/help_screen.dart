import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:docscanner/l10n/app_localizations.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.howToUse)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _FeatureCard(
            icon: Icons.color_lens_outlined,
            title: l10n.helpScanner,
            description: l10n.helpScannerDesc,
          ),
          _FeatureCard(
            icon: Icons.crop_outlined,
            title: l10n.helpBoundary,
            description: l10n.helpBoundaryDesc,
          ),
          _FeatureCard(
            icon: Icons.pages_outlined,
            title: l10n.helpMultiPage,
            description: l10n.helpMultiPageDesc,
          ),
          _FeatureCard(
            icon: Icons.text_snippet_outlined,
            title: l10n.helpOcr,
            description: l10n.helpOcrDesc,
          ),
          _FeatureCard(
            icon: Icons.picture_as_pdf_outlined,
            title: l10n.helpPdf,
            description: l10n.helpPdfDesc,
          ),
          _FeatureCard(
            icon: Icons.search_outlined,
            title: l10n.helpSearch,
            description: l10n.helpSearchDesc,
          ),
          _FeatureCard(
            icon: Icons.palette_outlined,
            title: l10n.helpThemes,
            description: l10n.helpThemesDesc,
          ),
          _FeatureCard(
            icon: Icons.restore_outlined,
            title: l10n.helpUndo,
            description: l10n.helpUndoDesc,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Text(l10n.about, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.aboutBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(l10n.privacyPolicy, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final url = Uri.parse(
                'https://raw.githubusercontent.com/mantunez94/docscanner/main/PRIVACY_POLICY.md');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              'raw.githubusercontent.com/mantunez94/docscanner/main/PRIVACY_POLICY.md',
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final url = Uri.parse(
                'https://github.com/mantunez94/docscanner/issues');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            child: Text(
              l10n.contactEmail,
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

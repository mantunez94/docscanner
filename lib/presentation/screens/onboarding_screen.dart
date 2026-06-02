import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docscanner/l10n/app_localizations.dart';
import '../../data/di/providers.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../providers/theme_provider.dart';
import '../theme/themes.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  List<_OnboardingPage> _buildPages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = ref.read(themeProvider);
    return [
      _OnboardingPage(
        icon: scanIcon(theme),
        title: l10n.onboardingScanTitle,
        description: l10n.onboardingScanDesc,
      ),
      _OnboardingPage(
        icon: Icons.tune,
        title: l10n.onboardingAdjustTitle,
        description: l10n.onboardingAdjustDesc,
      ),
      _OnboardingPage(
        icon: descriptionIcon(theme),
        title: l10n.onboardingOcrTitle,
        description: l10n.onboardingOcrDesc,
      ),
      _OnboardingPage(
        icon: pdfIcon(theme),
        title: l10n.onboardingExportTitle,
        description: l10n.onboardingExportDesc,
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setBool('onboarding_complete', true);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final pages = _buildPages(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _complete,
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(l10n.skip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (i) {
                final isLast = i == pages.length - 1;
                return Semantics(
                  label: 'Page ${i + 1} of ${pages.length}',
                  selected: _currentPage == i,
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? (isLast ? 32 : 24) : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withAlpha(60),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: isLast && _currentPage == i
                      ? const Icon(Icons.check, size: 6, color: Colors.white)
                      : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _currentPage == pages.length - 1
                      ? _complete
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                  child: Text(_currentPage == pages.length - 1 ? l10n.getStarted : l10n.next),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 64, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 32),
            Text(title, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> shouldShowOnboarding(PreferencesRepository prefs) async {
  final completed = await prefs.getBool('onboarding_complete') ?? false;
  return !completed;
}

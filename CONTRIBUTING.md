# Contributing to DocScanner

## Development Setup

### Prerequisites

- Flutter SDK (stable channel, matching `pubspec.yaml` SDK constraint)
- Android Studio / Xcode (for emulator/simulator)
- OpenCV native library (for `opencv_dart`)

### Local Environment

```sh
git clone <repo-url>
cd docscanner
flutter pub get
```

### Running Tests

```sh
# All tests (excluding golden)
flutter test --exclude-tags=golden

# Specific test file
flutter test test/presentation/screens/home_screen_test.dart
```

### Linting

```sh
flutter analyze
```

Must pass with **zero errors** before committing.

### Formatting

```sh
dart format lib/ test/
```

## Branch Naming

| Prefix | Purpose | Example |
|--------|---------|---------|
| `feature/` | New feature | `feature/document-favorites` |
| `bugfix/` | Bug fix | `bugfix/crash-on-empty-search` |
| `refactor/` | Code refactoring | `refactor/extract-crop-widget` |
| `docs/` | Documentation | `docs/update-architecture` |
| `test/` | Adding/fixing tests | `test/provider-coverage` |
| `chore/` | Maintenance | `chore/update-dependencies` |

## Commit Standards

Use [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Usage |
|------|-------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `refactor:` | Code change that neither fixes nor adds |
| `docs:` | Documentation only |
| `test:` | Adding or fixing tests |
| `chore:` | Build, CI, dependencies |
| `perf:` | Performance improvement |

Examples:
```
feat: add document favorites
fix: prevent crash when search query is empty
refactor: extract crop widget from preview screen
docs: update architecture diagram
test: add DocumentRepositoryImpl tests
chore: bump opencv_dart to 1.5.0
```

## Pull Request Workflow

1. Create a branch from `main` using the naming convention above.
2. Make your changes, following architecture rules in `docs/OPENCODE_RULES.md`.
3. Run `flutter analyze` and `flutter test`.
4. Create a PR targeting `main`.
5. Ensure CI passes.
6. Request review from a maintainer.

## Code Review Expectations

- Reviewers check architecture compliance (layer imports, dependency direction).
- Tests must be present for new functionality.
- No magic numbers or hardcoded strings.
- Error paths must be handled.
- No empty catch blocks.

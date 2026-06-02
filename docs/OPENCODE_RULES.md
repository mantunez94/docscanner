# DocScanner Engineering Handbook

> Repository-wide governance for human and AI contributors.
> Last updated: 2026-06-02

---

## Project Overview

| Property | Value |
|----------|-------|
| **Purpose** | 100% offline document scanner for Android (iOS planned) |
| **Language** | Dart 3.8+ |
| **Framework** | Flutter (Material 3) |
| **Architecture** | Hexagonal (Ports & Adapters) / Clean Architecture |
| **State management** | Riverpod 2.x |
| **Image processing** | OpenCV via `opencv_dart` FFI |
| **OCR** | Google ML Kit `google_mlkit_text_recognition` |
| **PDF generation** | `pdf` + `image` packages |
| **Persistence** | JSON file via `path_provider` + `shared_preferences` |
| **Themes** | 3 themes: Arcade, Kawaii, Professional |
| **Testing** | `flutter_test` + `mocktail` |
| **CI** | GitHub Actions (`flutter analyze` + `flutter test`) |

---

## Architecture Principles

### Hexagonal / Clean Architecture

The project follows a strict layered architecture with four main layers:

```
lib/
├── core/          # Infrastructure services (OCR, OpenCV processing)
├── data/           # Adapters-out (repositories, datasources, services)
├── domain/         # Core business logic (entities, ports, use cases)
└── presentation/  # Adapters-in (screens, providers, widgets)
```

### Layer Dependency Rules

| Layer | Can import from | Cannot import from |
|-------|----------------|-------------------|
| `domain/` | Dart SDK only | `dart:io`, Flutter, any package |
| `data/` | `domain/`, packages | Flutter widgets, Riverpod |
| `core/` | Any package | Flutter UI framework |
| `presentation/` | `domain/`, `data/` (via DI), `core/` (via providers) | Direct data layer bypass |

### How to implement

- **Domain entities** must be pure Dart classes with no dependencies.
- **Repository interfaces** (ports) are defined in `domain/repositories/`.
- **Use cases** orchestrate a single operation and depend only on repository interfaces.
- **Data implementations** are in `data/repositories/` and implement domain interfaces.
- **Dependency injection** is wired in `data/di/providers.dart`.
- **Presentation** uses Riverpod to connect use cases/services to UI.

### How NOT to implement

- ❌ Do not import `dart:io` or Flutter packages in `domain/`.
- ❌ Do not put business logic in widgets or screens.
- ❌ Do not create use cases that depend on concrete implementations (depend on abstractions).
- ❌ Do not bypass the repository layer to access datasources directly from presentation.

---

## Coding Standards

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.dart` | `document_repository.dart` |
| Classes | `PascalCase` | `ScannedDocument` |
| Abstract classes | `PascalCase` | `DocumentRepository` |
| Interfaces/Ports | `PascalCase` | `FileStorage`, `PdfGenerator` |
| Mixins | `PascalCase` | No mixins used |
| Extensions | `PascalCase` | No custom extensions |
| Enums | `PascalCase` | `AppTheme.arcade` |
| Enum values | `camelCase` | `AppTheme.professional` |
| Functions/methods | `camelCase` | `scanFromBytes()` |
| Variables | `camelCase` | `scannedDocument` |
| Constants | `lowerCamelCase` | `const testBannerAdUnitId` |
| Private members | `_camelCase` | `_cache` |
| Private files | `_prefix` only for private classes | ❌ Avoid private files |

### Folder Structure

```
lib/
├── core/
├── data/
│   ├── datasources/
│   ├── di/
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── l10n/
├── presentation/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   └── widgets/
└── main.dart
```

### Imports Order

1. `dart:` imports
2. `package:` imports (Flutter, external packages)
3. Project imports (`package:docscanner/...`)
4. Relative imports (for same-package files)

Separate groups with a blank line.

### Error Handling

- Use specific exception types, never generic `Exception`.
- Catch errors at the provider level, not in use cases.
- Use `AsyncValue` (AsyncNotifier) for async state in providers.
- Always handle errors in async operations with try/catch.
- Show user-friendly error messages via `ScaffoldMessenger.of(context).showSnackBar()`.
- Use `debugPrint()` for logging errors during development (never `print`).

### Async Code

- Use `Future` and `async/await` consistently.
- Return `Future<void>` for fire-and-forget operations.
- Use `unawaited()` for intentionally unawaited futures with explicit comment.
- Always check `mounted` after `await` in stateful widgets.

### Dependency Injection

- All dependencies are wired in `data/di/providers.dart`.
- Use `Provider<T>` for singletons (services, use cases).
- Use `AsyncNotifierProvider` for async state.
- Use `StateNotifierProvider` or `StateProvider` for synchronous state.
- Use `ref.read()` for one-time access, `ref.watch()` for reactive access.

---

## Approved Patterns

### Repository Pattern

**Purpose**: Abstract data access behind interfaces defined in the domain layer.

**Usage rules**:
- Interface in `domain/repositories/`.
- Implementation in `data/repositories/`.
- Return domain entities, never data models.

**Repository example**: `DocumentRepository` (domain) → `DocumentRepositoryImpl` (data).

### Use Case Pattern

**Purpose**: Encapsulate a single business operation.

**Usage rules**:
- One class per use case in `domain/usecases/`.
- Constructor takes repository interface.
- Single method `call()` with named parameters.

**Example**: `lib/domain/usecases/scan_document.dart`

### Provider Pattern (Riverpod)

**Purpose**: State management and dependency injection.

**Usage rules**:
- File per provider or logical group in `presentation/providers/`.
- Use `AsyncNotifierProvider` for async state.
- Invalidate providers to trigger refresh: `ref.invalidate(provider)`.

### Theme Pattern

**Purpose**: Multi-theme support with Material 3.

**Usage rules**:
- Define themes in `presentation/theme/themes.dart`.
- Use `AppTheme` enum for theme selection.
- Use icon helper functions (`scanIcon()`, `deleteIcon()`, etc.) for theme-aware icons.

---

## Forbidden Anti-Patterns

### Massive Widgets/Screens

**Why it is harmful**: Makes code hard to read, test, and maintain.

**Detection criteria**: Any screen file exceeding 400 lines.

**Refactoring strategy**: Extract sections into separate widget files in `presentation/widgets/`.

**Current violations**:
- `home_screen.dart` (693 lines)
- `scanner_screen.dart` (738 lines)
- `preview_screen.dart` (592 lines)

### Business Logic in UI

**Why it is harmful**: Violates Clean Architecture, makes testing impossible without widget tests.

**Detection criteria**: Widget files containing data transformation, file I/O, or domain logic.

**Refactoring strategy**: Move logic to use cases, providers, or core services.

### Shared Mutable State Outside Riverpod

**Why it is harmful**: Causes unpredictable behavior and race conditions.

**Detection criteria**: Global variables, static mutable state, singletons with mutable fields.

**Refactoring strategy**: Use Riverpod providers for all shared state.

### Hardcoded Values

**Why it is harmful**: Makes configuration changes impossible without code changes.

**Detection criteria**: Magic numbers, inline configuration, hardcoded file paths.

**Refactoring strategy**: Extract to constants or configuration providers.

### Empty Catch Blocks

**Why it is harmful**: Silently swallows errors, making debugging impossible.

**Detection criteria**: `catch (e) {}` or `catch (_) {}` without handling.

**Refactoring strategy**: At minimum log with `debugPrint()`, then handle appropriately.

### Duplicate Logic

**Why it is harmful**: Violates DRY, causes bugs when one copy is updated but not others.

**Detection criteria**: Similar code blocks appearing in multiple files.

**Refactoring strategy**: Extract to shared utilities in `core/` or shared methods.

**Current violations**:
- Corner detection logic duplicated between `DocumentBoundaryDetector` and `ImageProcessingService`.
- PDF generation logic duplicated in `PdfService.generatePdf()` and `PdfService.exportPdf()`.

---

## Feature Development Workflow

1. **Issue creation**: Create a GitHub issue with problem statement and acceptance criteria.
2. **Requirement analysis**: Document the feature in the issue.
3. **Architecture validation**: Identify which layers are affected. Add interfaces to `domain/` first.
4. **Implementation**:
   - Domain layer: entities → repository interfaces → use cases.
   - Data layer: models → datasource → repository impl → services → DI wiring.
   - Presentation: providers → screens/widgets.
5. **Testing**: Unit tests for domain/data/core, widget tests for presentation.
6. **Documentation**: Update relevant docs if public API changes.
7. **Pull request**: Create PR with description, screenshots (if UI), and checklist.

---

## Pull Request Standards

Every PR must pass:

- [ ] `flutter analyze` passes with 0 errors
- [ ] `flutter test` passes (excluding golden tests that require on-device regeneration)
- [ ] No new analyzer warnings introduced
- [ ] Architecture rules respected (check layer imports)
- [ ] Tests added for new functionality
- [ ] Documentation updated if public API changes
- [ ] Screenshots attached for UI changes
- [ ] GPG-signed commits
- [ ] Tested on a physical device

---

## Testing Standards

### Unit Tests

- Required for: domain entities, use cases, data models, core services.
- Use `mocktail` for mocking dependencies.
- Test success and error paths.

### Widget Tests

- Required for: screens, widgets, bottom sheets.
- Use `ProviderScope` to wrap widgets in tests.
- Test loading, data, and error states.

### Golden Tests

- Excluded from CI (`--exclude-tags=golden`).
- Must be regenerated on a device when UI changes.

### Coverage Expectations

- New code should have tests.
- Aim for >80% coverage on domain layer.
- Aim for >60% coverage on data layer.
- Screen/widget tests should cover main states (loading, data, error).

---

## Performance Guidelines

- Use `cacheWidth` on all `Image.file()` calls for thumbnails (400px cards, 120px reorder).
- Downsample camera frames for boundary detection (target width: 320px).
- Use `RepaintBoundary` for animated widgets (e.g., `ShimmerGrid`).
- Avoid `File.existsSync()` on UI thread — use `Image.file` errorBuilder instead.
- Avoid `setState` when value hasn't changed (use equality checks).

---

## Security Guidelines

- DocScanner is 100% offline — no network requests for core functionality.
- Camera permission must show rationale before requesting.
- Handle permission denial gracefully (show settings button).
- Never log sensitive data.
- Validate document names to prevent path traversal (`[<>:"/\\|?*]`).
- Use test ad unit IDs for development; replace with real IDs before release.

---

## Dependency Management Rules

- Pin major versions in `pubspec.yaml`.
- Use `dependency_overrides` only when necessary and document why.
- `package:image` is overridden to `4.8.0` — document in pubspec.
- Run `flutter pub outdated` before major updates.

---

## Documentation Standards

- README.md is the project entry point — keep it current.
- Architecture decisions go in `docs/ARCHITECTURE.md`.
- Engineering rules go in `docs/OPENCODE_RULES.md`.
- All public API should be self-documenting (clear names + types).
- Use Mermaid diagrams for architecture visuals.

---

## Technical Debt Register

| # | Issue | Severity | Layer |
|---|-------|----------|-------|
| 1 | `preview_screen.dart` (592 lines) — extract crop handling to dedicated widget | 🟡 MEDIUM | Presentation |
| 2 | `home_screen.dart` (693 lines) — extract batch operations, search, dialogs | 🟡 MEDIUM | Presentation |
| 3 | `scanner_screen.dart` (738 lines) — extract camera controller, overlay painter | 🟡 MEDIUM | Presentation |
| 4 | Corner detection duplicated in `DocumentBoundaryDetector` and `ImageProcessingService` | 🟡 MEDIUM | Core |
| 5 | `PdfService.generatePdf()` and `PdfService.exportPdf()` share ~80% logic | 🟢 LOW | Data |
| 6 | `ExportToPdf` use case is anemic — only collects paths, doesn't export | 🟢 LOW | Domain |
| 7 | No proper logging system — uses `debugPrint` | 🟢 LOW | Cross-cutting |
| 8 | Ad unit IDs hardcoded as constants | 🟢 LOW | Presentation |
| 9 | `shared_preferences` used directly without abstraction | 🟢 LOW | Presentation |
| 10 | Golden tests need on-device regeneration | 🟡 MEDIUM | Test |

---

## Golden Rules

1. **Domain has ZERO package dependencies** — pure Dart only.
2. **Interfaces in domain, implementations in data** — depend on abstractions.
3. **One use case = one responsibility** — never combine operations.
4. **No business logic in widgets** — use providers and use cases.
5. **Every async operation handles errors** — no empty catch blocks.
6. **`cacheWidth` on all thumbnails** — prevent full-resolution decode.
7. **Test success AND error paths** — both matter.
8. **No global mutable state** — use Riverpod providers.
9. **`flutter analyze` must pass before commit** — zero tolerance for warnings.
10. **Name validation uses `ScannedDocument.validateName()`** — always validate user input.

---

## AI Agent Operating Instructions

### Before Writing Code

Agents MUST:

1. Read `docs/ARCHITECTURE.md` and `docs/OPENCODE_RULES.md` first.
2. Search for existing implementations that may be reusable.
3. Check `data/di/providers.dart` for existing DI wiring.
4. Verify the feature fits within the established architecture.

### While Writing Code

Agents MUST:

1. Follow layer dependency rules (domain → data → presentation → core).
2. Add new repository interfaces to `domain/repositories/` before implementations.
3. Wire new dependencies in `data/di/providers.dart`.
4. Add unit tests for domain/data changes, widget tests for UI changes.
5. Use existing patterns (repository, use case, provider).

### Before Finishing Work

Agents MUST verify:

- [ ] `flutter analyze` passes with 0 errors
- [ ] `flutter test` passes for affected files
- [ ] No duplicate code introduced
- [ ] Architecture rules respected
- [ ] New dependencies justified (not added unnecessarily)

### Forbidden Agent Behaviors

- ❌ Creating new patterns without justification (stick to repository + use case + provider).
- ❌ Ignoring existing abstractions (always reuse `DocumentRepository`, `FileStorage`, etc.).
- ❌ Introducing duplicate code (extract shared logic to `core/`).
- ❌ Bypassing dependency rules (domain must not import Flutter).
- ❌ Adding unnecessary package dependencies.
- ❌ Modifying domain entities to include infrastructure concerns.
- ❌ Skipping tests for new functionality.

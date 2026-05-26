# Session Summary

## Project State (May 2026)

DocScanner is a Flutter Android document scanner with real-time boundary detection, auto-capture, OCR, perspective correction, image enhancement, and PDF export. Built with hexagonal architecture and SOLID principles.

### Completed (merged to main)

**Camera & Capture**
- Auto-capture with boundary detection: Y-plane → downsample (320px) → GaussianBlur → OTSU threshold → MORPH_CLOSE+MORPH_OPEN → findContours → minAreaRect → 4-corner ordering; Canny(30,100) fallback
- Auto-capture parameters: 12% minimum area, 5 consecutive detections
- YUV420 image stream processing (every 10th frame to avoid ImageReader buffer exhaustion on Samsung A13)
- Sensor orientation correction for correct overlay mapping
- Retake confirmation dialog
- Microphone permission: `enableAudio: false` in CameraController (never requested at runtime)
- Manual capture FAB removed — auto-capture only
- Home button (`home_outlined` icon) in scanner AppBar leading position
- **Batch scan**: FAB tap = single page; FAB hold = batch mode (after each page, asks "Scan another?"). All pages saved to same document.

**Image Processing**
- Perspective correction: OpenCV `getPerspectiveTransform2f` + `warpPerspective` (bypasses `flutter_image_perspective_crop` DNL JPEG bug on MediaTek)
- Image enhancement: `normalize(NORM_MINMAX)` → `convertScaleAbs(α=1.25, β=5)` → sharpen kernel center 5
- Document detection on captured photo (same pipeline as preview, at full resolution)

**Preview Screen**
- Draggable corner handles (4 cyan circles) for manual crop adjustment
- `applyDragToCorners()` function ensuring complete corner independence
- **Corner reset button**: `Icons.restart_alt` in bottom toolbar — restores auto-detected corners
- Crop overlay painter with 10×10 grid (white, alpha 40, 0.5px stroke)
- Two overlay modes: `fullOverlay=true` (dark exterior + lines + grid), `fullOverlay=false` (lines + grid only, no dark fill — used during corner drag)
- GPU-accelerated magnifier: `_MagnifierPainter` using `ui.Image` + `canvas.drawImageRect` for raw pixel zoom, 4×, 200px circle, positioned above finger (replaced `RawMagnifier` which showed overlay/circle pixels instead of image)

**PDF Generation**
- Dynamic `PdfPageFormat` per image aspect ratio (no white borders)
- Regenerates PDF on page add/remove/reorder

**Document Management**
- Multi-page documents with page grid view
- Individual page deletion with PDF regeneration
- Search with empty state icon
- Batch mode (multi-select delete)
- Rename documents
- Pull-to-refresh
- **Page reordering**: `ReorderableListView` with drag handle — accessed from action sheet ("Reorder pages") or directly from document detail

**OCR**
- Google ML Kit text recognition
- Bottom sheet results with copy-to-clipboard
- Button labeled "Extract Text" (icon-only with Tooltip)

**UI/UX**
- 3 themes: Arcade (PressStart2P + VT323), Kawaii (ShortStack), Professional (Inter)
- **Default theme changed to Professional**
- Onboarding carousel (4 pages, persisted via SharedPreferences)
- Shimmer skeleton loading grid
- Icon-only bottom toolbar (with Tooltip hints)
- Slide transitions between screens

**Infrastructure**
- GPG-signed commits (key 4FF9A0F2703EB38B7361978504F984B3F3189DA9)
- Pre-push hook: verify signed commits + flutter analyze (`--no-fatal-infos --no-fatal-warnings`)
- `ndkVersion = "27.0.12077973"`, `minSdk = 24` for opencv_dart
- ANDROID_HOME configured at `/opt/android-sdk`
- Build for armeabi-v7a: `flutter build apk --debug` (no `--target-platform android-arm64`)
- Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
- **AI assistant branching rules**: Never push directly to main — always create feature branches and PRs

### Known Issues

1. **4 OpenCV tests skipped on host** — native lib not available on host test runner; run on device only.
2. **Night/low-light boundary detection degrades** — mitigation ideas saved in `.opencode/night-detection-improvements.md` (CLAHE, adaptive Canny thresholds).
3. **Device USB disconnects after `adb install`** — app installs correctly but `flutter run` loses connection; launch manually from launcher.

### Recent Changes (2026-05-22)

**UX Audit — 58 hallazgos, ~33 resueltos en 5 PRs (#24–#28):**

| PR | Hallazgos | Cambios |
|----|-----------|---------|
| #24 | #16, #17, #11–#13, #24, #27, #29 | Semantic labels, camera permission, haptic, saving state, detection progress, discard dialog, disabled styles, undo delete |
| #25 | #8, #17b, #18, #20, #30, #31, #32, #48 | Icono back, batch mode title, Select All, onboarding re-entry, Kawaii snackbar, shimmer animation, gallery save feedback, reorder confirm |
| #26 | #22, #23, #39, #40, #47, #51 | Processing error SnackBar, OCR title size, onboarding checkmark, batch FAB animation, empty page state, action sheet icon |
| #27 | #21, #26, #37, #43, #44, #53 | Skip button touch target, add-page FAB, splash branding, cooldown indicator, semantic labels, shimmer font scale |
| #28 | #15, #34, #42, #49, #52 | Grid flicker fix, textScaleFactor clamp, detector params, thumbnail retry hint, delete dialog warning |

- **PDF regeneration after image editing**: Editing a page in PreviewScreen now writes the edited image bytes back to disk and regenerates the PDF, ensuring the PDF stays in sync with the edited image.
- **Night detection improvements** saved to `.opencode/night-detection-improvements.md`
- **All 7 GitHub issues (#16–#22) closed**
- **Device disconnected** — reconnect and run `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

### Recent Changes (2026-05-23 — Session 2)

**4 user-reported issues fixed — PRs #34–#37:**

| # | Problema | PR | Cambios |
|---|----------|----|---------|
| #30 | Mala detección en fondos claros | [#34](https://github.com/mantunez94/docscanner/pull/34) | CLAHE + Canny adaptativo + sync thresholds |
| #31 | Loop infinito al retomar captura | [#35](https://github.com/mantunez94/docscanner/pull/35) | Cooldown de 2s tras retake |
| #32 | Solo B&W sin opción color | [#36](https://github.com/mantunez94/docscanner/pull/36) | Toggle B&W/Color en toolbar |
| #33 | Flash de tema muestra código fuente | ~~#37 (ValueKey)~~ → [#66](https://github.com/mantunez94/docscanner/pull/66) | FadeTransition 150ms en builder |

**Architecture audit (2 violations fixed):**
- Domain: removed `package:intl` from `scanned_document.dart` — pure Dart date formatting
- Presentation: extracted DI wiring to `data/di/providers.dart` — no direct imports from `data/datasources/` or `data/repositories/`

**App deployed to device:** `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

**Production Readiness Audit** — Score: **52/100** — [Full report](PRODUCTION_AUDIT.md)
- 24 GitHub issues created (#39–#62) covering CRITICAL/HIGH/MEDIUM/LOW findings
- **Verdict: NOT READY** — estimated 4 weeks to production-ready

### Recent Changes (2026-05-23 — Session 3: Critical & High Issues)

**4 issues fixed — PRs #66–#70:**

| # | Severidad | Problema | PR | Cambios |
|---|-----------|----------|----|---------|
| #65 | CRITICAL | Theme flash entre temas no-Professional | [#66](https://github.com/mantunez94/docscanner/pull/66) | `ConsumerStatefulWidget` + `FadeTransition` 150ms, removido `ValueKey` |
| #41 | CRITICAL | setState cada 10 frames en cámara | [#67](https://github.com/mantunez94/docscanner/pull/67) | Solo setState si esquinas o detección cambian |
| #40 | CRITICAL | File.existsSync() en UI thread (GridView) | [#68](https://github.com/mantunez94/docscanner/pull/68) | `Image.file` + errorBuilder, removido existsSync |
| #39 | CRITICAL | ImgProc en Presentation layer (preview_screen) | [#69](https://github.com/mantunez94/docscanner/pull/69) | Nueva `ImageProcessingService` en `core/` |
| #42 | HIGH | Zero widget tests | [#70](https://github.com/mantunez94/docscanner/pull/70) | 22 tests en 5 pantallas (mocktail + Riverpod overrides) |

**Resumen de cambios:**

- **Theme flash (#33 → #65):** PR #37 usaba `key: ValueKey(currentTheme)` que causaba full remount y solo funcionaba desde Professional. Reemplazado por `FadeTransition` con `AnimationController` en `builder`, cross-fade de 150ms entre cualquier par de temas.
- **Camera performance (#41):** `_onImage` antes llamaba `setState(() => _corners = corners)` cada 10 frames aunque no cambiaran. Ahora compara old/new corners con `_cornersEqual` y setState solo si cambian o si `_detectedCount` cambió.
- **Sync I/O (#40):** `File.existsSync()` en `GridView.builder` y `ReorderableListView` bloqueaba UI thread. Reemplazado por `errorBuilder` en `Image.file`.
- **Arquitectura (#39):** 150 líneas de OpenCV (CLAHE, OTSU, contornos, warp, enhance) extraídas de `preview_screen.dart` a `core/image_processing_service.dart`.
- **Widget tests (#42):** 22 tests nuevos con mocktail para `DocumentRepository`. Test de las 5 pantallas: Onboarding (8), Home (6), Scanner (3), DocumentDetail (5), Preview (1 widget + 4 unit).

**Score actualizado:** Pendiente — auditoría completa necesita re-evaluación tras fixes críticos.

### Test Suite

- 60 tests total (4 skipped on host — OpenCV native lib):
- Entity serialization roundtrip
- Repository implementation (mocktail)
- Use case orchestration
- OCR service
- Document model
- Widget tests for all 5 screens
- Corner drag independence (`ImageProcessingService.applyDragToCorners`) — 4 unit tests

## System

- Flutter SDK: `/opt/flutter/bin` (v3.32.1, Dart 3.11.4)
- Android SDK: `/opt/android-sdk` (platform 35, ndk 27.0.12077973)
- Device: SM A137F (Samsung A13), serial RZ8T81FCDMM, Android 14 API 34, armeabi-v7a
- Platform: Arch Linux, user `miguelaaga`
- Project: `/home/miguelaaga/Projects/docscanner`
- Remote: `https://github.com/mantunez94/docscanner`
- GPG key: `4FF9A0F2703EB38B7361978504F984B3F3189DA9`

### Recent Changes (2026-05-26 — Session 4: Torch + Multi-page + Save-As + Hexagonal)

**4 PRs merged:**

| PR | Descripción |
|----|-------------|
| [#93](https://github.com/mantunez94/docscanner/pull/93) | **Torch toggle**: `FlashMode.torch` button in scanner AppBar, auto-off on dispose, widget test |
| [#94](https://github.com/mantunez94/docscanner/pull/94) | **Multi-page scan mode**: separate toggle, thumbnail strip, `MultiPageReviewScreen` |
| [#95](https://github.com/mantunez94/docscanner/pull/95) | **Always multi-page**: removed toggle, multi-page is now the default scanner behavior |
| [#96](https://github.com/mantunez94/docscanner/pull/96) | **Save-As + single document**: all captured pages save as one document; Save-As dialog with editable filename + duplicate detection; camera dispose crash fixes |
| [#98](https://github.com/mantunez94/docscanner/pull/98) | **Hexagonal architecture**: 5 domain interfaces, god class split, DIP in DI layer |

**Arquitectura (score: 45 → 68/100):**
- 5 interfaces en `lib/domain/repositories/`: `FileStorage`, `PdfGenerator`, `GallerySaver`, `DocumentDataSource`, `OcrTextRecognizer`
- `DocumentListNotifier` → 5 providers enfocados: `DocumentScan`, `DocumentPageManager`, `DocumentAdmin`, `DocumentExport`, `DocumentListNotifier`
- `MlKitTextRecognizer implements OcrTextRecognizer`; DI retorna interfaces
- `flutter analyze`: 0 errores | `flutter test`: 81/81 pass (4 skip)

**Bugs corregidos:**
- **Crash en dispose**: `CameraException` por `stopImageStream` duplicado + `CameraController used after disposed` por `setFlashMode` asíncrono — ambos con guardas y try-catch

**Deployed:** `adb install -r build/app/outputs/flutter-apk/app-debug.apk` — app launches and renders (verified via logcat)

### Architecture items deffered from this session

| Item | SOLID | Razón |
|------|-------|-------|
| `LocalDataSource implements DocumentDataSource` | DIP | Low priority — `DocumentRepositoryImpl` already bridges correctly |
| `ImageProcessingService` → interfaz `ImageProcessor` en `domain/repositories/` | DIP | Clase concreta sin puerto; `ScannerScreen`/`PreviewScreen` la importan directamente |
| Inyectar image processing vía DI en screens | DIP | Screens instancian `ImageProcessingService()` directamente sin pasar por provider |
| Extraer lógica de cámara de `ScannerScreen` | DIP + SRP | `_ScannerScreenState` maneja `CameraController`, stream, auto-capture, torch, flash — todo junto |
| `CameraService` interfaz en `domain/repositories/` | DIP | Sin abstracción, la screen depende directamente de `package:camera` |
| ISP para `DocumentRepository` | ISP | 8 métodos; `ScanDocument` solo usa `save`, `GetAllDocuments` solo `getAll` — cada use case depende de métodos que no necesita |
| Anemic domain model (#48) | OCP | `ScannedDocument` es data class sin comportamiento; lógica de negocio (validación, factory methods) en providers/screens |

### Test Suite

- **81 tests total** (4 skipped on host — OpenCV native lib):
- 60 pre-existing (entity, repository, use case, OCR, widget, corner drag)
- **+21 new**: torch toggle (3), multi-page review (4), scanner capture flow (6), save-as dialog (4), document save (4)

## System

- Flutter SDK: `/opt/flutter/bin` (v3.32.1, Dart 3.11.4)
- Android SDK: `/opt/android-sdk` (platform 35, ndk 27.0.12077973)
- Device: SM A137F (Samsung A13), serial RZ8T81FCDMM, Android 14 API 34, armeabi-v7a
- Platform: Arch Linux, user `miguelaaga`
- Project: `/home/miguelaaga/Projects/docscanner`
- Remote: `https://github.com/mantunez94/docscanner`
- GPG key: `4FF9A0F2703EB38B7361978504F984B3F3189DA9`

## Next Steps

### Mañana — Quick wins (~1h)
1. ✅ PR #98 ya mergeado — `git pull` en main
2. `LocalDataSource implements DocumentDataSource`
3. Interfaz `ImageProcessor` en `domain/repositories/` + implementación
4. Inyectar `ImageProcessor` vía provider en `ScannerScreen` y `PreviewScreen`
5. Desplegar: `flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk`

### Mañana — Bloque grande (2-3h)
6. Interfaz `CameraService` en `domain/repositories/`
7. Extraer cámara/pipeline de `ScannerScreen` → `CameraServiceImpl` en `data/services/`

### Próximas sesiones
- ISP: dividir `DocumentRepository` en interfaces pequeñas
- Anemic domain model (#48): mover lógica a `ScannedDocument`
- Producción (#52, #53, #55, #56): tablet layout, features faltantes, assets Play Store

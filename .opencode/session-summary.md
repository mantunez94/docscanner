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

### Recent Changes (2026-05-23)

**4 user-reported issues fixed — PRs #34–#37:**

| # | Problema | PR | Cambios |
|---|----------|----|---------|
| #30 | Mala detección en fondos claros | [#34](https://github.com/mantunez94/docscanner/pull/34) | CLAHE + Canny adaptativo + sync thresholds |
| #31 | Loop infinito al retomar captura | [#35](https://github.com/mantunez94/docscanner/pull/35) | Cooldown de 2s tras retake |
| #32 | Solo B&W sin opción color | [#36](https://github.com/mantunez94/docscanner/pull/36) | Toggle B&W/Color en toolbar |
| #33 | Flash de tema muestra código fuente | [#37](https://github.com/mantunez94/docscanner/pull/37) | `ValueKey` en MaterialApp para rebuild atómico |

**Architecture audit (2 violations fixed):**
- Domain: removed `package:intl` from `scanned_document.dart` — pure Dart date formatting
- Presentation: extracted DI wiring to `data/di/providers.dart` — no direct imports from `data/datasources/` or `data/repositories/`

**App deployed to device:** `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

### Test Suite

- 37 tests total (4 skipped on host):
- Entity serialization roundtrip
- Repository implementation (mocktail)
- Use case orchestration
- OCR service
- Document model
- Corner drag independence (`applyDragToCorners`) — 4 unit tests

## System

- Flutter SDK: `/opt/flutter/bin` (v3.32.1, Dart 3.11.4)
- Android SDK: `/opt/android-sdk` (platform 35, ndk 27.0.12077973)
- Device: SM A137F (Samsung A13), serial RZ8T81FCDMM, Android 14 API 34, armeabi-v7a
- Platform: Arch Linux, user `miguelaaga`
- Project: `/home/miguelaaga/Projects/docscanner`
- Remote: `https://github.com/mantunez94/docscanner`
- GPG key: `4FF9A0F2703EB38B7361978504F984B3F3189DA9`

## Next Steps (suggested order)

1. **Widget tests** — search, batch mode, onboarding, OCR, document detail, boundary overlay painters
2. **Play Store prep** — app icon, splash branding, CI/CD, screenshots, description
3. **Night detection** — CLAHE + adaptive Canny implemented in #34, verify on device
4. **Remaining low-priority items** — torch toggle, pinch-to-zoom, text scaling beyond clamped range

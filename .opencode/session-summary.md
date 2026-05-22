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
2. **`document_processor.dart`** in `core/` is not used — all processing is inlined in `preview_screen.dart`.
3. **`_imageMat` (cv.Mat)** stored field may be unused after removing OpenCV-based magnifier — verify in refactor pass.

### Recent Changes (2026-05-22) - Batch 2: UX Audit Fixes #16-#22

All 7 GitHub issues from the UX audit are now resolved:

- **#18 Fixed**: Onboarding page 2 copy updated — "Filters & Adjustments" → "Adjust & Refine" with accurate descriptions for perspective correction and corner adjustment.
- **#21 Fixed**: Inverted font size hierarchy in Arcade theme — `titleLarge` increased (20px PressStart2P), `titleMedium` reduced (18px VT323), `titleSmall` reduced (16px VT323) to match M3 spec.
- **#19 Fixed**: SnackBar only shows "Document saved"/"Pages added" when actual scanning occurred — tracks `pagesScanned` counter and returns `true` from scanner in batch mode.
- **#20 Fixed**: All raw exception strings replaced with human-readable messages — scanner capture, PDF export, and OCR extraction errors now show user-friendly text.
- **#22 Fixed**: Gallery/disk saves happen after database write to prevent orphaned files on failure — `scanFromBytes` and `addPageToDocument` reordered; added `_cleanupFiles` to remove orphaned files if database write fails.
- **#16 Fixed**: Semantic labels added across all screens for TalkBack accessibility — FAB tooltip, boundary overlay, crop overlay, magnifier, corner handles, search field, page indicator dots, page thumbnails, drag handles, document card thumbnails all wrapped in `Semantics` with descriptive labels.
- **#17 Fixed**: Camera permission request flow — rationale dialog before system prompt, graceful handling of denied/permanently-denied states, `openAppSettings()` button, retry button for non-permission errors, user-friendly error messages replacing raw exceptions.

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

1. **Verify dark mode across all 3 themes** — ensure complete dark variants
2. **Widget tests** — search, batch mode, onboarding, OCR, document detail, boundary overlay painters
3. **App icon + splash screen branding**
4. **Play Store prep** — CI/CD, screenshots, description

# Session Summary

## Project State (May 2026)

DocScanner is a Flutter Android document scanner with real-time boundary detection, auto-capture, OCR, perspective correction, image enhancement, and PDF export. Built with hexagonal architecture and SOLID principles.

### Completed (merged to main)

**Camera & Capture**
- Auto-capture with boundary detection: Y-plane → downsample (320px) → GaussianBlur → OTSU threshold → MORPH_CLOSE+MORPH_OPEN → findContours → minAreaRect → 4-corner ordering; Canny(30,100) fallback
- YUV420 image stream processing (every 10th frame to avoid ImageReader buffer exhaustion on Samsung A13)
- Sensor orientation correction for correct overlay mapping
- Retake confirmation dialog

**Image Processing**
- Perspective correction: OpenCV `getPerspectiveTransform2f` + `warpPerspective` (bypasses `flutter_image_perspective_crop` DNL JPEG bug on MediaTek)
- Image enhancement: normalize(NORM_MINMAX) → convertScaleAbs(α=1.2, β=10) → sharpen kernel
- Document detection on captured photo (same pipeline as preview, at full resolution)

**Preview Screen**
- Draggable corner handles (4 cyan circles) for manual crop adjustment
- Crop overlay painter (darkened exterior + cyan quad border)
- RawMagnifier during corner drag (positioned above finger with focalPointOffset — pending improvement)

**PDF Generation**
- Dynamic `PdfPageFormat` per image aspect ratio (no white borders)
- Regenerates PDF on page add/remove

**Document Management**
- Multi-page documents with page grid view
- Individual page deletion with PDF regeneration
- Search with empty state icon
- Batch mode (multi-select delete)
- Rename documents
- Pull-to-refresh

**OCR**
- Google ML Kit text recognition
- Bottom sheet results with copy-to-clipboard
- Button labeled "Extract Text" (icon-only with Tooltip)

**UI/UX**
- 3 themes: Arcade (PressStart2P + VT323), Kawaii (ShortStack), Professional (Inter)
- Onboarding carousel (4 pages, persisted via SharedPreferences)
- Shimmer skeleton loading grid
- Icon-only bottom toolbar (with Tooltip hints)
- Slide transitions between screens

**Infrastructure**
- GPG-signed commits (key 2B6CDC4D14A73A91)
- Pre-push hook: verify signed commits + flutter analyze
- `ndkVersion = "27.0.12077973"`, `minSdk = 24` for opencv_dart
- ANDROID_HOME configured at `/opt/android-sdk`

### Known Issues

1. **Magnifier** — `RawMagnifier` shows the overlay + handle pixels, not clean image. Needs custom implementation that extracts a Mat ROI around the corner and displays it zoomed in a floating widget (extract 40x40 px → resize 4x → show in ClipOval).
2. **4 OpenCV tests skipped on host** — native lib not available on host test runner; run on device only.
3. **`document_processor.dart`** in `core/` is not used — all processing is inlined in `preview_screen.dart` for simplicity. Should be refactored.

### Recent Changes

- **Auto-capture tuning** (2026-05-22): Increased area threshold from 10% → 15% and consecutive detections from 5 → 8 to give more time to center the document before capture.

### Test Suite

36 tests total (4 skipped on host):
- Entity serialization roundtrip
- Repository implementation (mocktail)
- Use case orchestration
- OCR service
- Document model

## System

- Flutter SDK: `/opt/flutter/bin` (v3.32.1, Dart 3.11.4)
- Android SDK: `/opt/android-sdk` (platform 35, ndk 27.0.12077973)
- Device: SM A137F (Samsung A13), serial RZ8T81FCDMM, Android 14 API 34
- Platform: Arch Linux, user `miguelaaga`
- Project: `/home/miguelaaga/Projects/docscanner`
- Remote: `https://github.com/mantunez94/docscanner`
- GPG key: `2B6CDC4D14A73A91`

## Next Steps (suggested order)

1. **Fix magnifier** — custom widget: extract Mat ROI (40x40 px) from `_imageMat` around corner, resize 4x, encode as PNG, display in ClipOval above drag point
2. **Manual corner reset** — allow user to reset corners to auto-detected position
3. **Auto-capture tuning** — verify 3-frame threshold vs 8% fill fraction on real device scenarios
4. **Dark mode per-theme** — verify all 3 themes have complete dark variants
5. **Widget tests** — search, batch mode, onboarding, OCR, document detail, boundary overlay painters
6. **App icon + splash screen branding**
7. **Play Store prep** — CI/CD, screenshots, description

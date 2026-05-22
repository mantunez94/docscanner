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

**Image Processing**
- Perspective correction: OpenCV `getPerspectiveTransform2f` + `warpPerspective` (bypasses `flutter_image_perspective_crop` DNL JPEG bug on MediaTek)
- Image enhancement: `normalize(NORM_MINMAX)` → `convertScaleAbs(α=1.25, β=5)` → sharpen kernel center 5
- Document detection on captured photo (same pipeline as preview, at full resolution)

**Preview Screen**
- Draggable corner handles (4 cyan circles) for manual crop adjustment
- `applyDragToCorners()` function ensuring complete corner independence
- Crop overlay painter with 10×10 grid (white, alpha 40, 0.5px stroke)
- Two overlay modes: `fullOverlay=true` (dark exterior + lines + grid), `fullOverlay=false` (lines + grid only, no dark fill — used during corner drag)
- GPU-accelerated magnifier: `_MagnifierPainter` using `ui.Image` + `canvas.drawImageRect` for raw pixel zoom, 4×, 200px circle, positioned above finger (replaced `RawMagnifier` which showed overlay/circle pixels instead of image)

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

### Known Issues

1. **4 OpenCV tests skipped on host** — native lib not available on host test runner; run on device only.
2. **`document_processor.dart`** in `core/` is not used — all processing is inlined in `preview_screen.dart`.
3. **`_imageMat` (cv.Mat)** stored field may be unused after removing OpenCV-based magnifier — verify in refactor pass.

### Recent Changes (2026-05-22)

- **Auto-capture tuning**: 10%→15%→12% area, 5→8→5 consecutive detections. Final params (12%, 5 detections) balance fast capture with avoiding false triggers.
- **Image enhancement retuned**: Changed from hard defaults to `normalize` + `convertScaleAbs(α=1.25, β=5)` + sharpen center 5 — subtle enhancement without overprocessing.
- **Custom magnifier** (2 iterations): Replaced `RawMagnifier` with GPU-accelerated `_MagnifierPainter` using `ui.instantiateImageCodec` + `drawImageRect` — 4× zoom, 200px circle, positioned above finger. Shows only raw image pixels. Avoids OpenCV encode/decode overhead.
- **Grid overlay**: Rule-of-thirds → 10×10 grid (white, alpha 40, 0.5px stroke) inside crop area.
- **Overlay during drag**: Changed from hidden overlay to showing only quad lines + grid (no dark fill) so magnifier stays clean while corners remain visually connected.
- **Corner independence**: Extracted `applyDragToCorners()` function — ensures each corner moves independently. 4 unit tests added.
- **Microphone permission**: `CameraController(enableAudio: false)` — avoids runtime RECORD_AUDIO prompt without removing manifest declaration (camera plugin requires it).
- **Manual capture removed**: FAB deleted — auto-capture only workflow.
- **Default theme**: Changed from Arcade to Professional.
- **Home button**: Close icon (X) → home icon (`home_outlined`).

### Test Suite

40 tests total (4 skipped on host):
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

1. **Manual corner reset** — allow user to reset corners to auto-detected position
2. **Verify dark mode across all 3 themes** — ensure complete dark variants
3. **Widget tests** — search, batch mode, onboarding, OCR, document detail, boundary overlay painters
4. **App icon + splash screen branding**
5. **Play Store prep** — CI/CD, screenshots, description

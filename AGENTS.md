# Session — 31 May 2026

## Goal
- Debug and fix scanner overlay misalignment (first scan "un poco mas abajo").
- Deploy fix to Samsung A13, then PR and merge to main.

## Done
- **Diagnosed root cause**: `_buildOverlay` centered the paint area (`offsetY=22`) via `(bodyH - paintH) / 2`, but `CameraPreview` is an unpositioned `Stack` child that naturally sits at `(0,0)`. The overlay corners were drawn 22px below the actual camera preview.
- **Why it seemed to fix itself**: After the first capture, the page strip (80px) appeared, reducing `bodyH` until `paintH` matched exactly (`offsetY=0`), making the misalignment disappear.
- **Fix**: Changed `offsetX = offsetY = 0.0` in `_buildOverlay` (scanner_screen.dart:422-423).
- **Deploy**: Built APK, installed on Samsung A13 (`adb install -r`), user confirmed "ahora si perfecto".
- **PR #106**: Created, merged squash to main, signed commit (`6ba3c69`).

## Key Files Changed
- `lib/presentation/screens/scanner_screen.dart` — removed centering offset from overlay paint area.

## Notes
- Warmup (30-frame skip + `_frameCount = 0` on stream restart) kept as defense-in-depth for camera exposure stabilization.
- Debug logging (`debugPrint` in `_onImage` and `_buildOverlay`) used for diagnosis, then removed.

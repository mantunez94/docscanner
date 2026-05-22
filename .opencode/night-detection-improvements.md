# Night / Low-Light Boundary Detection Improvements

## Problem

Boundary detection performs worse in low-light conditions (night). Current algorithm
uses Canny (30,100) which is sensitive to noise when contrast is low.

## Proposed Solutions (in priority order)

### 1. CLAHE Equalization Before Detection

Apply Contrast Limited Adaptive Histogram Equalization (CLAHE) to the Y (luminance)
plane before running OTSU/Canny. This significantly improves edge contrast in
low-light frames.

```dart
final clahe = CLAHE.create(clipLimit: 2.0, tileGridSize: Size(8, 8));
clahe.apply(yPlaneMat);
```

Location: `document_boundary_detector.dart`, before Gaussian blur (~line 40).

### 2. Adaptive Canny Thresholds Based on Mean Luminance

Detect if frame is low-light by measuring mean pixel value of the Y plane.
Adjust Canny thresholds dynamically:

```dart
final mean = Core.mean(yPlaneMat)[0];
double low, high;
if (mean < 50) {
  low = 20; high = 60;   // Low light: more sensitive, tighter range
} else if (mean < 100) {
  low = 30; high = 100;  // Medium light: current defaults
} else {
  low = 50; high = 150;  // Bright light: less sensitive
}
```

Location: `document_boundary_detector.dart`, before Canny edge detection (~line 54).

### 3. Increase Morphological Operations in Low Light

More aggressive closing to fill gaps caused by low contrast:

```dart
final closeIterations = mean < 50 ? 4 : 3;
final openIterations = mean < 50 ? 3 : 2;
```

### 4. Increase Gaussian Blur in Low Light

Reduce noise before thresholding:

```dart
final blurKernel = mean < 50 ? Size(7, 7) : Size(5, 5);
```

### 5. Sync Canny Thresholds Between Live and Post-Capture

Live detector uses Canny (30,100) but post-capture detector (`preview_screen.dart`)
uses Canny (50,150). Sync them so what you see live matches the preview.

Fix: change `preview_screen.dart` line ~100 to match or make both adaptive.

## Files to Modify

| File | Lines |
|------|-------|
| `lib/core/document_boundary_detector.dart` | ~40-60 |
| `lib/presentation/screens/preview_screen.dart` | ~100 |
| `lib/presentation/screens/scanner_screen.dart` | (none) |

## Testing

- Test at different light levels (bright office, dim room, near-dark)
- Verify auto-capture still triggers reliably
- Check that OTSU path still works (it's adaptive by nature)

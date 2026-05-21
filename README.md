# DocScanner

Multi-theme document scanner for Android with OCR, PDF export, and automatic image enhancement.

## Architecture

Hexagonal (ports & adapters) with strict layer isolation:

```mermaid
flowchart TB
    subgraph Presentation["Presentation Layer (adapters/in)"]
        Screens["screens/\n(UI pages)"]
        Widgets["widgets/\n(Reusable components)"]
        Providers["providers/\n(Riverpod state management)"]
        Theme["theme/\n(Theming system)"]
    end

    subgraph Domain["Domain Layer (core business)"]
        Entities["entities/\n(ScannedDocument, OcrResult)"]
        RepoPorts["repositories/\n(Port interfaces)"]
        UseCases["usecases/\n(ScanDocument, DeleteDocument, etc.)"]
    end

    subgraph Data["Data Layer (adapters/out)"]
        RepoImpl["repositories/\n(Repository implementations)"]
        DataSource["datasources/\n(LocalDataSource — JSON persistence)"]
        Models["models/\n(Data models / DTOs)"]
        Services["services/\n(FileService — I/O, PDF, gallery)"]
    end

    subgraph Core["Core Infrastructure"]
        OcrService["ocr_service.dart\n(Google ML Kit OCR)"]
        DocProcessor["document_processor.dart\n(OpenCV auto-enhancement)"]
    end
    
    subgraph External["External Dependencies"]
        Camera["Camera\n(android / camera)"]
        Storage["File system\n(path_provider)"]
        Gallery["Gallery\n(gal)"]
        OCR["Google ML Kit\n(text_recognition)"]
        OpenCV["OpenCV\n(opencv_dart FFI)"]
    end

    Screens --> Providers
    Widgets --> Screens
    Providers --> UseCases
    Providers --> Core
    UseCases --> RepoPorts
    UseCases --> Entities
    RepoPorts <--> RepoImpl
    RepoImpl --> DataSource
    RepoImpl --> Models
    RepoImpl --> Services
    Services --> DocProcessor
    Services --> Gallery
    Services --> Storage
    Core --> OCR
    Core --> OpenCV
    Camera --> Screens
    Storage --> DataSource

    classDef domain fill:#1a1a2e,color:#e94560,stroke:#e94560
    classDef data fill:#16213e,color:#0f3460,stroke:#0f3460
    classDef presentation fill:#0f3460,color:#e94560,stroke:#e94560
    classDef core fill:#533483,color:#e94560,stroke:#e94560
    classDef external fill:#2d2d2d,color:#888,stroke:#555

    class Entities,RepoPorts,UseCases domain
    class RepoImpl,DataSource,Models,Services data
    class Screens,Widgets,Providers,Theme presentation
    class OcrService,DocProcessor core
    class Camera,Storage,Gallery,OCR,OpenCV external
```

### Layer Rules

| Layer | Can import from | Cannot import from |
|-------|----------------|-------------------|
| `domain/` | Dart SDK only, domain entities | `dart:io`, packages, any framework |
| `data/` | Domain interfaces, packages | UI framework (Flutter widgets/riverpod) |
| `presentation/` | Domain entities, providers, `data/` services | Directly |
| `core/` | Any package | UI framework |

- **Domain** has zero external dependencies — pure Dart business logic
- **Data** implements domain ports with real I/O (JSON, files, PDF, gallery)
- **Presentation** uses Riverpod to coordinate between services and use cases
- **Core** holds infrastructure services (OCR, image processing)

## Tech Stack

| Concern | Library |
|---------|---------|
| State management | Riverpod |
| Camera | `camera` |
| Image processing | `opencv_dart` (FFI) + `image` |
| OCR | `google_mlkit_text_recognition` |
| PDF generation | `pdf` |
| Gallery save | `gal` |
| Persistence | JSON file via `path_provider` |
| Image crop | `flutter_image_perspective_crop` |
| Themes | 3 themes (Arcade, Kawaii, Professional) |

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── document_processor.dart    # OpenCV auto-enhance pipeline
│   └── ocr_service.dart           # Google ML Kit OCR
├── data/
│   ├── datasources/
│   │   └── local_datasource.dart  # JSON file persistence
│   ├── models/
│   │   └── scanned_document_model.dart
│   ├── repositories/
│   │   └── document_repository_impl.dart
│   └── services/
│       └── file_service.dart      # File I/O, PDF, gallery ops
├── domain/
│   ├── entities/
│   │   ├── ocr_result.dart
│   │   └── scanned_document.dart
│   ├── repositories/
│   │   └── document_repository.dart  # Port interface
│   └── usecases/
│       ├── add_pages_to_document.dart
│       ├── delete_document.dart
│       ├── export_to_pdf.dart
│       ├── get_all_documents.dart
│       ├── rename_document.dart
│       └── scan_document.dart
└── presentation/
    ├── providers/
    │   ├── document_provider.dart    # Document list state
    │   ├── ocr_provider.dart         # OCR state
    │   └── theme_provider.dart       # Theme state
    ├── screens/
    │   ├── home_screen.dart          # Document list + search + batch
    │   ├── onboarding_screen.dart    # First-run carousel
    │   ├── preview_screen.dart       # Crop + OCR
    │   └── scanner_screen.dart       # Camera capture
    ├── theme/
    │   └── themes.dart               # Arcade / Kawaii / Professional
    └── widgets/
        ├── document_actions_sheet.dart
        ├── document_card.dart
        └── shimmer_grid.dart
```

## Features

- **Auto-enhance**: OpenCV OTSU binarization + deskew on every scan
- **PDF-first**: Generates PDF immediately after crop, regenerates on page add
- **OCR**: Google ML Kit text recognition with copy-to-clipboard
- **Search & batch**: Filter documents by name, multi-select delete
- **Pull-to-refresh**: Refresh document list
- **3 themes**: Arcade (neon retro), Kawaii (pastel cute), Professional (clean)
- **Onboarding**: 4-page first-run carousel persisted via SharedPreferences
- **Gallery save**: JPG saved to phone gallery automatically
- **Share**: Shares PDF when available, falls back to JPG

## Testing

```
flutter test
```

37 tests (4 skipped on host — require native OpenCV lib present on device):
- Entity serialization tests
- Repository implementation tests
- Use case orchestration tests
- OCR service tests
- Document model roundtrip tests

## Build

```sh
# Debug APK
flutter build apk --debug --target-platform android-arm64

# Release APK (with ABI splits + minification)
flutter build apk --release
```

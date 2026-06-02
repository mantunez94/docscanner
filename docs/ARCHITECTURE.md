# DocScanner Architecture

> Repository-specific architecture documentation.
> Last updated: 2026-06-02

---

## High-Level Architecture

```mermaid
flowchart TB
    subgraph Presentation["Presentation Layer"]
        Screens["screens/\n(UI pages)"]
        Widgets["widgets/\n(Reusable components)"]
        Providers["providers/\n(Riverpod state)"]
        Theme["theme/\n(Theming system)"]
        PServices["services/\n(Ads, Undo)"]
    end

    subgraph Domain["Domain Layer"]
        Entities["entities/\n(ScannedDocument, OcrResult)"]
        Ports["repositories/\n(Port interfaces)"]
        UseCases["usecases/\n(Business operations)"]
    end

    subgraph Data["Data Layer"]
        RepoImpl["repositories/\n(Impl)"]
        DataSource["datasources/\n(LocalDataSource)"]
        Models["models/\n(DTOs)"]
        DServices["services/\n(File, PDF, Gallery)"]
        DI["di/\n(Dependency injection)"]
    end

    subgraph Core["Core Infrastructure"]
        Boundary["document_boundary_detector.dart"]
        ImgProc["image_processing_service.dart"]
        DocProc["document_processor.dart"]
        OCR["ocr_service.dart"]
    end

    subgraph External["External Dependencies"]
        Camera["camera"]
        Storage["path_provider"]
        Gallery["gal"]
        MLKit["google_mlkit_text_recognition"]
        OpenCV["opencv_dart"]
        Ads["google_mobile_ads"]
    end

    Screens --> Widgets
    Screens --> Providers
    Providers --> UseCases
    Providers --> PServices
    Providers --> Core
    UseCases --> Ports
    Ports <--> RepoImpl
    RepoImpl --> DataSource
    RepoImpl --> Models
    RepoImpl --> DServices
    DServices --> Storage
    DServices --> Gallery
    DServices --> DocProc
    Core --> MLKit
    Core --> OpenCV
    Core --> Boundary
    Core --> ImgProc
    Camera --> Screens
    Storage --> DataSource
    Ads --> PServices
    DI --> RepoImpl
    DI --> DServices
    DI --> UseCases

    classDef domain fill:#1a1a2e,color:#e94560,stroke:#e94560
    classDef data fill:#16213e,color:#0f3460,stroke:#0f3460
    classDef presentation fill:#0f3460,color:#e94560,stroke:#e94560
    classDef core fill:#533483,color:#e94560,stroke:#e94560
    classDef external fill:#2d2d2d,color:#888,stroke:#555

    class Entities,Ports,UseCases domain
    class RepoImpl,DataSource,Models,DServices,DI data
    class Screens,Widgets,Providers,Theme,PServices presentation
    class Boundary,ImgProc,DocProc,OCR core
    class Camera,Storage,Gallery,MLKit,OpenCV,Ads external
```

## Layer Responsibilities

### Domain Layer (`lib/domain/`)

The innermost layer with zero dependencies on Flutter or any external package.

**Entities** (`entities/`):
- `ScannedDocument` — Core domain model representing a scanned document with pages, name, dates, and PDF path.
- `OcrResult` / `OcrBlock` — OCR recognition results.

**Ports** (`repositories/`):
- `DocumentRepository` — CRUD operations for scanned documents.
- `DocumentDataSource` — Lower-level data source abstraction.
- `FileStorage` — Save page images and thumbnails.
- `GallerySaver` — Save to device gallery.
- `PdfGenerator` — Generate and export PDFs.
- `OcrTextRecognizer` — Text recognition abstraction.

**Use Cases** (`usecases/`):
- `ScanDocument` — Create a single-page document.
- `GetAllDocuments` — List all documents.
- `DeleteDocument` — Remove a document.
- `RenameDocument` — Rename a document.
- `AddPagesToDocument` — Append pages to existing document.
- `RemovePageFromDocument` — Remove a specific page.
- `ExportToPdf` — Collect page paths for PDF export.

### Data Layer (`lib/data/`)

Implements domain ports with real I/O operations.

**Datasource** (`datasources/`):
- `LocalDataSource` — JSON file persistence with in-memory cache. Reads/writes `documents/index.json` in app documents directory.

**Models** (`models/`):
- `ScannedDocumentModel` — JSON-serializable DTO with `fromJson`/`toJson` and `fromEntity`/`toEntity` mappers.

**Repository Implementation** (`repositories/`):
- `DocumentRepositoryImpl` — Delegates to `LocalDataSource`, maps between models and entities.

**Services** (`services/`):
- `FileService` — Saves page images and thumbnails to disk (implements `FileStorage`).
- `PdfService` — Generates PDFs with per-image aspect ratio (implements `PdfGenerator`).
- `GalleryService` — Saves images to device gallery via `gal` package (implements `GallerySaver`).

**DI** (`di/`):
- `providers.dart` — Wires all Riverpod providers for repository, services, and use cases.

### Presentation Layer (`lib/presentation/`)

Flutter UI with Riverpod state management.

**Screens** (`screens/`):
- `HomeScreen` — Document grid with search, batch mode, themes, PDF export.
- `ScannerScreen` — Camera preview with real-time boundary detection, capture, multi-page.
- `PreviewScreen` — Crop adjustment with draggable corners, magnifier, OCR trigger.
- `DocumentDetailScreen` — Page grid with reorder, batch delete, add page.
- `MultiPageReviewScreen` — Review captured pages before saving.
- `OnboardingScreen` — First-run carousel (4 pages).
- `HelpScreen` — Feature descriptions and links.

**Providers** (`providers/`):
- `theme_provider.dart` — Theme selection and mode (light/dark/system).
- `document_provider.dart` — Document list async state.
- `document_scan_provider.dart` — Scan orchestration (save, PDF, gallery, invalidation).
- `document_export_provider.dart` — Bulk PDF export.
- `document_page_provider.dart` — Page management (add, remove, reorder).
- `document_admin_provider.dart` — Delete, restore, rename.
- `ocr_provider.dart` — OCR state.

**Services** (`services/`):
- `ad_service.dart` — Google Mobile Ads banner and native ad lifecycle.
- `undo_service.dart` — Undo action state (used for delete restoration).

**Theme** (`theme/`):
- `themes.dart` — Three complete Material 3 themes: Arcade (neon retro), Kawaii (pastel), Professional (corporate).

**Widgets** (`widgets/`):
- `DocumentCard` — Grid card with thumbnail, name, page count, selection state.
- `DocumentActionsSheet` — Bottom sheet with rename, add page, share, delete actions.
- `BannerAdWidget` — Banner ad container.
- `PostSaveAdCard` — Native ad card shown after saving.
- `ShimmerGrid` — Loading skeleton with animated shimmer.
- `ResponsiveUtils` — Cross-axis count helper (2/3/4 columns).

### Core Layer (`lib/core/`)

Infrastructure services that bridge to native/platform capabilities.

- `document_boundary_detector.dart` — Real-time document boundary detection from camera Y-plane using OpenCV (CLAHE + OTSU + morphology + Canny fallback).
- `document_processor.dart` — Auto-enhance pipeline (deskew + OTSU threshold).
- `image_processing_service.dart` — Complete image processing: corner detection, perspective transform, enhance (B&W/color), encode.
- `ocr_service.dart` — Google ML Kit OCR wrapper with `OcrTextRecognizer` protocol.

---

## Dependency Rules

### Allowed Dependencies

| Source Layer | Can Import |
|-------------|------------|
| `domain/` | Dart SDK only |
| `data/` | `domain/`, `package:*` (external packages) |
| `core/` | `domain/`, `package:*` (external packages) |
| `presentation/` | `domain/`, `core/`, `data/di/`, `package:flutter`, `package:flutter_riverpod` |
| `test/` | All layers, `package:flutter_test`, `package:mocktail` |

### Forbidden Dependencies

| Source Layer | Cannot Import |
|-------------|---------------|
| `domain/` | `dart:io`, `dart:html`, any package, Flutter |
| `data/` | Flutter widgets, Riverpod, Flutter framework |
| `core/` | Flutter widgets |
| `presentation/` | `data/datasources/`, `data/models/` directly (go through repositories) |

---

## Module Boundaries

### Document Creation Flow

```
ScannerScreen
  └─ capture() → CameraController.takePicture()
      └─ ImageProcessingService.detectDocumentFromMat()
      └─ ImageProcessingService.processScan()
      └─ PreviewScreen (optional edit)
          └─ processScan() with adjusted corners
      └─ MultiPageReviewScreen (reorder, edit, delete pages)
          └─ onSave → DocumentScan.scanFromMultipleBytes()
              └─ FileService.savePageImage() + saveThumbnail()
              └─ ScanDocument use case → DocumentRepository.save()
              └─ PdfService.generatePdf()
              └─ GalleryService.saveToGallery()
              └─ ref.invalidate(documentListProvider)
```

### Document Viewing Flow

```
HomeScreen
  └─ DocumentListNotifier.build() → GetAllDocuments use case
      └─ DocumentRepository.getAll()
          └─ LocalDataSource.loadAll()
  └─ GridView of DocumentCard widgets
      └─ onTap → showDocumentActionsSheet
          └─ Rename / Add Page / Share / Delete / View Pages
```

---

## Data Flow

### Read Path

```
Screen → ref.watch(provider) → UseCase → Repository (interface) → RepositoryImpl → DataSource → JSON file → Model → Entity → Provider → Screen rebuild
```

### Write Path

```
Screen → ref.read(provider).method() → UseCase → Repository (interface) → RepositoryImpl → DataSource → JSON file → Model → Entity → Provider invalidation → Screen rebuild
```

---

## State Management Flow

```mermaid
sequenceDiagram
    participant Screen as Screen (Widget)
    participant Provider as Riverpod Provider
    participant UseCase as Use Case
    participant Repo as Repository

    Screen->>Provider: ref.watch(provider)
    Provider->>UseCase: build() / call()
    UseCase->>Repo: call()
    Repo-->>UseCase: result
    UseCase-->>Provider: data
    Provider-->>Screen: AsyncData / AsyncLoading / AsyncError

    Note over Screen,Provider: Mutation path
    Screen->>Provider: ref.read(provider).method()
    Provider->>UseCase: call()
    UseCase->>Repo: call()
    Repo-->>UseCase: result
    Provider->>Provider: ref.invalidate(documentListProvider)
    Provider-->>Screen: rebuild
```

---

## Error Handling Flow

```mermaid
flowchart LR
    A[User Action] --> B{Provider method}
    B -->|success| C[Invalidate provider]
    B -->|error| D[Set AsyncError on provider]
    C --> E[Screen rebuilds with data]
    D --> F[Screen shows error state]
    D --> G[debugPrint for developers]
```

- Providers catch errors and expose them via `AsyncValue.error`.
- Screens use `.when(loading, error, data)` to render appropriate UI.
- `ScaffoldMessenger.of(context).showSnackBar()` for transient error feedback.
- `debugPrint()` for development logging (replaced by proper logger in future).

---

## Feature Creation Blueprint

### Example: Creating a "Favorite Documents" feature

1. **Domain layer**:
   - Add `isFavorite` field to `ScannedDocument` entity.
   - Add `toggleFavorite` method to `DocumentRepository` interface.
   - Create `ToggleFavoriteDocument` use case.

2. **Data layer**:
   - Add `isFavorite` to `ScannedDocumentModel` with JSON serialization.
   - Implement `toggleFavorite` in `LocalDataSource`.
   - Implement `toggleFavorite` in `DocumentRepositoryImpl`.
   - Wire `ToggleFavoriteDocument` in `data/di/providers.dart`.

3. **Core layer**: (not needed for this feature)

4. **Presentation layer**:
   - Add favorite icon to `DocumentCard`.
   - Add toggle action to `DocumentActionsSheet`.
   - Update `HomeScreen` to filter by favorites if needed.

5. **Tests**:
   - Update `ScannedDocumentModelTest` for new field.
   - Update `DocumentRepositoryImplTest`.
   - Add `ToggleFavoriteDocumentTest`.
   - Update `DocumentCardTest` and `HomeScreenTest`.

---

## Document Relationship Diagram

```mermaid
classDiagram
    class ScannedDocument {
        +String id
        +List~String~ pages
        +String thumbnailPath
        +DateTime createdAt
        +String name
        +String? pdfPath
        +int pageCount
        +String filePath
        +addPage(String) ScannedDocument
        +removePage(String) ScannedDocument
        +replacePage(int, String) ScannedDocument
        +reorderPages(List~String~) ScannedDocument
        +updatePdfPath(String) ScannedDocument
        +copyWith() ScannedDocument
        +validateName(String?) String?
    }

    class ScannedDocumentModel {
        +String id
        +String filePath
        +List~String~ pages
        +String thumbnailPath
        +DateTime createdAt
        +String name
        +String? pdfPath
        +fromEntity(ScannedDocument) ScannedDocumentModel
        +toEntity() ScannedDocument
        +toJson() Map~String,dynamic~
        +fromJson(Map) ScannedDocumentModel
    }

    class DocumentRepository {
        <<interface>>
        +getAll() List~ScannedDocument~
        +save(ScannedDocument) ScannedDocument
        +delete(String) void
        +rename(String, String) ScannedDocument
        +addPages(String, List~String~) ScannedDocument
        +removePage(String, String) ScannedDocument
        +reorderPages(String, List~String~) ScannedDocument
        +updatePdfPath(String, String) void
    }

    class DocumentRepositoryImpl {
        +getAll() List~ScannedDocument~
        +save(ScannedDocument) ScannedDocument
        +delete(String) void
        +rename(String, String) ScannedDocument
        +addPages(String, List~String~) ScannedDocument
        +removePage(String, String) ScannedDocument
        +reorderPages(String, List~String~) ScannedDocument
        +updatePdfPath(String, String) void
    }

    class LocalDataSource {
        -List~ScannedDocumentModel~ _cache
        +loadAll() List~ScannedDocumentModel~
        +save(ScannedDocumentModel) void
        +rename(String, String) ScannedDocumentModel
        +addPages(String, List~String~) ScannedDocumentModel
        +removePage(String, String) ScannedDocumentModel
        +updatePdfPath(String, String) void
        +reorderPages(String, List~String~) ScannedDocumentModel
        +delete(String) void
    }

    ScannedDocumentModel ..> ScannedDocument : maps to/from
    DocumentRepositoryImpl ..|> DocumentRepository : implements
    DocumentRepositoryImpl --> LocalDataSource : delegates to
    DocumentRepositoryImpl --> ScannedDocumentModel : uses
    LocalDataSource --> ScannedDocumentModel : persists
```

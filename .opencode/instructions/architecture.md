# Architecture & SOLID

## Hexagonal Architecture (Ports & Adapters)

Strict layer isolation — dependency rule: outer layers depend on inner layers, never the reverse.

```
presentation/  →  domain/   ←  data/
     ↓                        ↑
     └──── core/infra ────────┘
```

### Layer Rules

| Layer | Can import | Cannot import |
|-------|-----------|---------------|
| `domain/` | Dart SDK only (core, typed_data) | `dart:io`, any package, Flutter |
| `data/` | Domain interfaces, any package | Flutter widgets, Riverpod |
| `presentation/` | Domain entities, providers, `data/` services | Domain implementation details |
| `core/` | Any package | Flutter widgets / Riverpod |

### Specific rules
- **`domain/` use cases** MUST NOT import `dart:io`, `package:image`, `package:pdf`, `package:gal`, `package:path_provider`
- **`domain/` use cases** MUST NOT write files, encode/decode images, generate PDFs, or save to gallery
- All infrastructure (file I/O, PDF generation, image processing, gallery save) goes in `data/services/` or `core/`
- Providers in `presentation/providers/` orchestrate: service → use case → repository
- Repository interfaces (ports) live in `domain/repositories/`
- Repository implementations live in `data/repositories/`

## SOLID Principles

### S — Single Responsibility
- Each class has exactly one reason to change
- A use case does ONE thing (e.g. `ScanDocument` creates an entity and saves it — it does NOT process images or generate PDFs)
- A service does ONE thing (e.g. `FileService` handles file I/O — it does NOT contain business rules)

### O — Open/Closed
- Extend behavior via new use cases / services, not by modifying existing ones
- Adding a new storage backend? Create a new datasource implementing the existing interface — don't modify existing datasources

### L — Liskov Substitution
- Repository implementations must honor the contract defined by their interface
- Mock implementations in tests must behave like real ones

### I — Interface Segregation
- Keep repository interfaces small and focused
- `DocumentRepository` only exposes document CRUD operations, not file storage concerns

### D — Dependency Inversion
- High-level modules (domain) define interfaces; low-level modules (data) implement them
- `DocumentRepository` (interface in `domain/repositories/`) → `DocumentRepositoryImpl` (in `data/repositories/`)
- Use cases depend on the abstract repository interface, never on the concrete implementation

## Current Compliance Gaps

Score: **68/100** — checklist priorizado para próxima sesión:

| # | Gap | Violación | Impacto | Esfuerzo |
|---|-----|-----------|---------|----------|
| 1 | `LocalDataSource implements DocumentDataSource` | DIP | Bajo | 15min |
| 2 | Interfaz `ImageProcessor` en `domain/repositories/` + `ImageProcessingService implements ImageProcessor` | DIP | Medio | 30min |
| 3 | Inyectar `ImageProcessor` vía provider en screens | DIP | Medio | 30min |
| 4 | `CameraService` interfaz en `domain/repositories/` + implementación en `data/services/` | DIP + SRP | Alto | 2-3h |
| 5 | Extraer lógica de cámara de `ScannerScreen` → `CameraService` | SRP | Alto | 2-3h |
| 6 | Dividir `DocumentRepository` en interfaces pequeñas (ej. `DocumentReader`, `DocumentWriter`, `DocumentPageEditor`) | ISP | Bajo | 1h |
| 7 | Mover lógica de negocio a entidades dominio (`ScannedDocument` con factory methods, validación) | OCP | Medio | 2h |

**Para mañana**: Items 1→3 son quick wins (~1h total). Items 4→5 son el bloque grande pendiente.

## Test Structure
- Tests mirror `lib/` structure in `test/`
- Domain tests mock repository interfaces with `mocktail`
- Data tests mock datasource interfaces
- Tests for infrastructure that depends on native libraries (OpenCV, ML Kit) are skipped on host with clear reasoning

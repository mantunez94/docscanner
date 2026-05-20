# Git Workflow

## Branching (GitHub Flow)
- `main` → siempre estable y desplegable
- `feat/<nombre>` → nueva funcionalidad, nace de `main`
- `fix/<nombre>` → corrección de bugs, nace de `main`
- `chore/<nombre>` → tareas técnicas (refactors, deps, CI)

## Pull Requests
- Siempre PR de rama a `main`
- Mantener PRs pequeños (una funcionalidad por PR)
- Título del PR: mismo formato que commits

## Commits (Conventional Commits)
```
feat: descripción en presente y en español
fix: descripción en presente y en español
chore: descripción en presente y en español
docs: descripción en presente y en español
```

Ejemplos:
- `feat: añadir exportación a PDF`
- `fix: corregir crash al rotar imagen`
- `chore: actualizar dependencias`

## Commits firmados
- Todos los commits deben ir firmados con GPG (`git commit -S`)
- El hook pre-push lo verifica automáticamente

## Antes de un PR
1. `git pull --rebase origin main`
2. Resolver conflictos si los hay
3. `flutter analyze` sin errores
4. Push a la rama y crear PR

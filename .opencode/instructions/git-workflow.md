# Git Workflow

## Branching (GitHub Flow)
- `main` → always stable and deployable
- `feat/<name>` → new feature, branched from `main`
- `fix/<name>` → bug fix, branched from `main`
- `chore/<name>` → technical tasks (refactors, deps, CI)

## Pull Requests
- Always PR from feature branch to `main`
- Keep PRs small (one feature per PR)
- PR title follows the same format as commits

## Commits (Conventional Commits — English only)
```
feat: description in present tense in English
fix: description in present tense in English
chore: description in present tense in English
docs: description in present tense in English
```

Examples:
- `feat: add PDF export`
- `fix: fix crash on image rotation`
- `chore: update dependencies`

## Code language
- All code: identifiers, comments, strings, commits → **English only**
- UI text shown to the user can be in any language

## Signed commits
- Every commit must be GPG-signed (`git commit -S`)
- The pre-push hook verifies this automatically

## Before a PR
1. `git pull --rebase origin main`
2. Resolve any conflicts
3. `flutter analyze` with no errors
4. Push branch and create PR

# ABKO System

Company internal systems repository.

## Delivery pipelines

### Web app
- Web UI work is committed to this repo (e.g. `ui-mock/`).
- Review: use githack/raw links (or wire GitHub Pages later).

### Desktop app (Windows)
- Scaffold: `desktop-app/`
- Build artifacts (.exe + .zip): GitHub Actions workflow `desktop-build`
  - Run: GitHub → Actions → `desktop-build` → Run workflow
  - Download: artifact `abkosystem-desktop-windows`

## Projects

### CS Improvement Program (WIP)

Goal: improve CS/AS intake and ticket management without breaking existing workflows.

- Customer intake page (external)
- CS management program (internal)
- Data model designed for future AI expansion (call recordings, transcripts, summaries, monitoring)

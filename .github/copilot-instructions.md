# Copilot Instructions

## For GitHub Copilot and AI Agents

- **Always use the Makefile for all build, dependency installation, and release tasks.**
- Do not use shell scripts or manual commands for ISO generation, dependency setup, or releases.
- Use these Makefile targets:
  - `make iso` — Build the tayyebi-os ISO
  - `make build-deps` — Install all local build dependencies (cross-distro)
  - `make contrib-prereq` — Install contributor prerequisites (cross-distro)
  - `make release` — Tag and create a GitHub release (requires `gh` CLI)
- If you need to add new automation, prefer Makefile targets over shell scripts.
- Keep all automation portable and cross-distro compatible.

---

**Author:** GitHub Copilot

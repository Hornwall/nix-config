# AGENTS.md

Guidance for coding agents working in this repository.

## Repository scope

- This is a Nix-based system configuration repository.
- Keep changes minimal, explicit, and reproducible.
- Prefer extending existing modules/overlays over introducing new top-level patterns.

## Layout

- `nixos/`: NixOS host and system modules.
- `home-manager/`: user-level Home Manager configuration.
- `pkgs/`: custom package definitions.
- `overlays/`: nixpkgs overlays.
- `shells/`: development shell definitions.
- `flake.nix`: flake inputs/outputs entry point.

## Editing rules

- Match existing style and naming in nearby files.
- Keep modules focused; avoid broad refactors unless requested.
- Do not move or rename files unless needed for the task.
- Do not commit secrets, tokens, or machine-specific credentials.

## Validation

Run the narrowest relevant checks first, then broader ones when needed.

- `nix flake check`
- `nix flake show`

If a host-specific change is made, prefer evaluating that target only.

## Agent workflow

- Explain planned changes briefly before editing when the task is non-trivial.
- After edits, report:
  - Files changed
  - Why each change was made
  - What checks were run (or why not)
- Do not create commits or branches unless explicitly requested.

---
name: codex-dream-skin-studio
description: Install, customize, launch, verify, repair, update, or restore Codex Dream Skin Studio on macOS. Use when a user supplies one background image and wants Codex personalized from that image, wants to replace the current theme or background, or needs safe CDP theme troubleshooting and rollback while preserving the native interface.
---

# Codex Dream Skin Studio

This file is an optional Codex capability entry. The delivery is a complete standalone project; users do not need to install it as a Skill.

## Workflow

1. Treat the supplied image as the only required creative input. Inspect it, infer a fitting name, copy, and restrained palette; ask only when the image or intent is genuinely ambiguous.
2. For an existing personalized installation, preserve the established CSS coverage and replace the mutable image/theme data under Application Support. Do not regenerate the theme with generic defaults when the request is only to change the background.
3. For a new installation, run `Install Codex Dream Skin.command`, then customize from the image.
4. Hot-apply through the verified loopback CDP session. Restart Codex only when the endpoint is unavailable and the user has authorized it.
5. Verify both a normal task and the settings renderer. Include the personal menu, composer-adjacent overlays, ChatGPT page, right/bottom panels, settings sidebar/content/cards/forms, and settings popups.
6. Restore the official appearance with `Restore Codex Dream Skin.command` when requested.

Read [references/one-image-theme-workflow.md](references/one-image-theme-workflow.md) whenever the user provides a new image or asks to replace the current personalized theme. Read [references/surface-selector-recipes.md](references/surface-selector-recipes.md) before editing any page, panel, menu, popup, or settings styling. Read [references/dock-launcher-workflow.md](references/dock-launcher-workflow.md) when creating, repairing, re-iconing, or re-adding the optional Dock launcher. These references are the implementation source of truth; do not rediscover known surfaces or launcher behavior from screenshots.

## Guardrails

- Never modify the official `.app`, `app.asar`, or its code signature.
- Use the official Codex app's signed Node.js runtime only after validating its signature, Team ID, architecture, and minimum version.
- Bind CDP to loopback, verify that the listener belongs to Codex, and reject non-Codex renderer targets.
- Preserve all native cards, navigation, project selectors, task content, composer controls, and keyboard focus.
- Keep existing broad shell and portal coverage when changing only theme data; do not narrow selectors to the currently visible route.
- Keep decoration at `pointer-events: none`.
- Require explicit authorization before restarting an already-running Codex instance.
- Stop an injector only when its recorded PID, executable, command line, and start time all match.

## Key resources

- `README.md`: user installation and customization guide.
- `scripts/injector.mjs`: CDP connection, injection, removal, verification, and screenshots.
- `assets/dream-skin.css`: live native interface styling.
- `assets/renderer-inject.js`: idempotent DOM integration and cleanup.
- `scripts/doctor-macos.sh`: signed-runtime, payload, and optional live-session self-check.
- `references/surface-selector-recipes.md`: exact selector, CSS, injector, and hot-apply recipes for every covered surface.
- `references/dock-launcher-workflow.md`: reproducible app wrapper, icon, signing, LaunchServices, Dock, running-indicator, and question-mark repair procedure.
- `references/qa-inventory.md`: release and visual acceptance criteria.

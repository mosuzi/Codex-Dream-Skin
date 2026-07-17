# One-image personalized theme workflow

Use this playbook when the user supplies one background image and asks to replace or restyle the active Codex theme. The image is the only required input.

## Input contract

- Inspect the image before changing anything. Infer a concise theme name, atmosphere, copy, focal crop, and small color palette from it.
- Do not ask the user to provide colors, CSS selectors, slogans, or installation paths unless the image or intent is genuinely ambiguous.
- If the request is only “换背景图”, preserve the current metadata and palette and change only the prepared image plus the `image` field.
- If the request is “换主题”, derive coherent tokens from the image while preserving the established UI coverage.

## Source of truth and mutable paths

- Source repo: this `macos/` directory.
- Installed engine: `~/.codex/codex-dream-skin-studio`.
- Active mutable theme: `~/Library/Application Support/CodexDreamSkinStudio/theme`.
- Runtime state: `~/Library/Application Support/CodexDreamSkinStudio/state.json`.
- Structural theme coverage: `assets/dream-skin.css`.
- Renderer recognition and verification: `scripts/injector.mjs`.
- Direct implementation map: `references/surface-selector-recipes.md`.

Never modify the official app, `app.asar`, its signature, or native application data.

## Current moonlit baseline

Use the active `theme/theme.json` as the first template. The known-good dark moonlit palette is:

```json
{
  "background": "#080B18",
  "panel": "#10172A",
  "panelAlt": "#19213A",
  "accent": "#A8D8FF",
  "accentAlt": "#D9EDFF",
  "secondary": "#B8C7FF",
  "highlight": "#C7A7E8",
  "text": "#F7F4FF",
  "muted": "#BEC7DA",
  "line": "rgba(168, 216, 255, 0.30)"
}
```

Keep text and muted-text contrast high. Prefer one pale accent, one supporting cool tone, and one restrained highlight; avoid scattering unrelated saturated colors across controls.

## Execution

1. Inspect the repo status, active `theme.json`, live Codex route, CDP port, and injector state. Preserve unrelated worktree changes.
2. Back up the current mutable `theme/` directory before replacement.
3. Prepare the supplied image as PNG, JPEG, or WebP, no larger than 16 MB. A wide crop around 2400–3200 px works well; keep the main face or focal subject away from dense native text.
4. Put the prepared image inside the mutable theme directory with mode `0600`.
5. Update `theme.json` atomically. Preserve `schemaVersion`, use only a local basename in `image`, and update `id`; change name, copy, and colors only when restyling rather than replacing the background.
6. Keep `assets/dream-skin.css` unchanged for an ordinary image/palette switch. Before any structural edit, use `references/surface-selector-recipes.md`; inspect live DOM only if its documented selector no longer matches after a Codex update.
7. Hot-reapply through the existing verified injector. If source CSS or injector logic changed, copy those two files to the installed engine before reloading and keep repo/installed copies identical.
8. Leave the app on a useful themed page for the user and retain the backup until visual verification passes.

Do not use a generic customization preset for a background-only refresh: presets may overwrite the established palette and copy.

## Coverage matrix

Verify the real native DOM, not only a screenshot:

- Home banner, suggestion cards, project selector, composer, and normal task background.
- Messages, approvals, output/source layers, scrollbars, focus, hover, and keyboard input.
- Quota/status layer, queue, thread summary, slash-command palette, and other composer portals.
- Built-in ChatGPT chat page, right sidebar, and bottom panel.
- Personal/profile menu and ordinary Radix menus, including selected and hover states.
- Settings renderer: left navigation/search, main background, cards, inputs, buttons, switches, tables, dropdowns, listboxes, dialogs, and scrollbars.
- At minimum open Settings from the personal menu and sample General, Appearance, and Plugins.
- Check both dark and light shell rules when the user may switch appearance modes.

## Acceptance gates

- Run `cd macos && npm test` and `git diff --check` when source files changed.
- Run the installed injector with `--verify` on a normal task and again on the settings renderer; both must report `pass: true` with no horizontal overflow.
- Compare source and installed CSS/injector files when either was changed.
- Capture live screenshots of the personal menu and settings page, and inspect computed backgrounds/borders for at least one portal menu and one settings card/switch.
- Confirm the persistent injector job is running and `state.json` records its current PID, start time, port, theme directory, and Codex PID.
- Do not commit or push unless the user asks separately.

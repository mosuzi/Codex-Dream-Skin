# Surface selector and styling recipes

Use this implementation map before changing a covered Codex surface. Do not start by identifying pages from screenshots. Start from these selectors and CSS section comments; use CDP DOM inspection only when a documented selector has stopped matching after an app update. Screenshots are for final visual QA.

## Contents

1. [Theme token flow](#theme-token-flow)
2. [Base shell and background](#base-shell-and-background)
3. [Composer overlays and ChatGPT](#composer-overlays-and-chatgpt)
4. [Right sidebar and bottom panel](#right-sidebar-and-bottom-panel)
5. [Profile and ordinary menus](#profile-and-ordinary-menus)
6. [Settings renderer](#settings-renderer)
7. [Injector recognition](#injector-recognition)
8. [Hot apply](#hot-apply)
9. [Fallback DOM inspection](#fallback-dom-inspection)

## Theme token flow

`assets/renderer-inject.js` reads `theme.json` in `applyTheme()` and sets these root variables:

| `theme.json` | CSS variable | Responsibility |
| --- | --- | --- |
| `colors.background` | `--ds-bg` | deepest shell background |
| `colors.panel` | `--ds-panel` | primary panels |
| `colors.panelAlt` | `--ds-panel-2` | elevated cards and glass |
| `colors.accent` | `--ds-green` | primary accent, focus, selected state |
| `colors.accentAlt` | `--ds-lime` | secondary accent variant |
| `colors.secondary` | `--ds-cyan` | supporting cool accent |
| `colors.highlight` | `--ds-purple` | restrained radial highlight |
| `colors.text` | `--ds-text` | primary text |
| `colors.muted` | `--ds-muted` | descriptions and inactive controls |
| `colors.line` | `--ds-line` | theme-defined line color |
| prepared image | `--dream-skin-art` | background image blob URL |

For image, copy, or palette-only changes, edit the mutable image and `theme.json`; do not edit page selectors. Dark mode consumes the full palette. Light mode intentionally keeps neutral structural surfaces and reuses accent colors.

The shared dark glass recipe is: a low-opacity purple/cyan radial highlight, a `--ds-panel-2` to `--ds-bg` linear gradient, `--ds-text`, a pale accent border, a dark outer shadow, a faint cyan inset line, and blur. Reuse the variables instead of hard-coded page colors.

## Base shell and background

Edit the existing anchored sections in `assets/dream-skin.css`:

| Surface | Selector or integration | Method |
| --- | --- | --- |
| document | `html.codex-dream-skin body` | set the global gradient and text color |
| normal sidebar | `aside.app-shell-left-panel` | themed vertical panel; keep native navigation interactive |
| normal main shell | `main.main-surface` | set shell border, radius, and base background |
| task image | `main.main-surface:not(.dream-skin-home-shell)` | layer readable gradients over `var(--dream-skin-art)` |
| task content | `main.main-surface:not(.dream-skin-home-shell) [role="main"]` | keep a subtle readability veil, not an opaque panel |
| composer | `.composer-surface-chrome` | glass border/background/shadow; keep `overflow: visible` |
| home content | `[role="main"].dream-skin-home` | style the live banner/cards/project selector |
| home shell state | `main.main-surface.dream-skin-home-shell` | distinguish home from ordinary tasks |

`assets/renderer-inject.js` assigns `dream-skin-home` and `dream-skin-home-shell`. Preserve that integration; do not infer home state from localized text. The injected decorative root is `#codex-dream-skin-chrome` and must remain `pointer-events: none`.

For a new image, adjust only the gradient opacity and `background-position` needed to protect the focal subject. Keep native text and controls as DOM; never rasterize UI into the image.

## Composer overlays and ChatGPT

These surfaces are body-level portals, not descendants of `.composer-surface-chrome`. The CSS section begins with `Composer portals, the native quota/status panel`.

| Surface | Stable selector |
| --- | --- |
| current status / composer portal | `:is(#above-composer-portal, #above-composer-queue-portal) [class*="bg-token-input-background"]` |
| quota/session status layer | `[class~="rounded-t-xl"][class~="bg-token-input-background"]:has(> [class~="font-mono"])` |
| thread summary | `[class~="bg-token-dropdown-background"]:has([data-slot="thread-summary-panel-item-button"])` |
| built-in ChatGPT conversation surface | `section[role="dialog"][class~="bg-token-dropdown-background"]:has([contenteditable="true"])` |
| slash-command palette | `[class~="bg-token-dropdown-background/90"][class~="max-h-[320px]"]:has(> .vertical-scroll-fade-mask)` |

Apply the shared glass recipe to the roots, then use these child rules:

- Status/quota: style the first header row, description text, numeric/mono buttons, and quota values under the same root selector.
- Composer portals: style descendant buttons and their `:hover` or `[data-state="open"]` states.
- Thread summary: use `data-slot="thread-summary-panel-item-button"` and `data-slot="thread-summary-panel-item-label"`; style its header and row hover independently.
- ChatGPT conversation: give the dialog a larger radius and style its buttons; the surrounding page still inherits the normal main-shell background.
- Slash commands: target `.vertical-scroll-fade-mask > button`, including hover, focus, and current-token hover classes.

Do not collapse these into `[class*="dropdown"]`; that selector is too broad and can recolor unrelated native surfaces.

## Right sidebar and bottom panel

Use the app-shell focus-area attributes; do not locate these panels by screen position:

```css
:is(
  [data-app-shell-focus-area="right-panel"],
  [data-app-shell-focus-area="bottom-panel"]
)
```

The visible surface is one level below the focus root:

```css
> [class~="absolute"][class~="inset-0"]
> [class~="bg-token-main-surface-primary"]
```

Make intermediate `bg-token-main-surface-primary` wrappers transparent, theme the visible child with the shared glass recipe, recolor `border-token-border`, then style buttons and active/selected/hover states. This structure covers the output/source sidebar and terminal/bottom panel without affecting the central chat surface.

## Profile and ordinary menus

The bottom profile menu and settings select menus share the same body-level Radix root:

```css
[role="menu"][class~="bg-token-dropdown-background/90"]
```

Style the root glass once. Style children with:

```css
:is([role="menuitem"], [role="menuitemradio"], [role="menuitemcheckbox"])
```

Use `:hover`, `:focus`, `[data-highlighted]`, and `[aria-checked="true"]` for interactive states; style `[role="separator"]`, `hr`, and `kbd` separately. Do not target menu text such as “设置” or “剩余用量”, because UI language and account content vary.

## Settings renderer

The settings page is a separate shell. Its sidebar and main surface are `div` elements, not the `aside` and `main` tags used by normal tasks. This tag mismatch was the original reason settings ignored the theme.

Use the language-independent route marker:

```css
.app-shell-left-panel:has([data-settings-panel-slug])
```

The exact structure and recipes are:

| Surface | Selector | Method |
| --- | --- | --- |
| settings sidebar | `.app-shell-left-panel:has([data-settings-panel-slug])` | full-height panel gradient, right border, shadow |
| search shell | sidebar + `[class*="bg-token-input-background"]` | translucent input background and accent border |
| search input | sidebar + `[role="searchbox"]` | text and caret colors |
| navigation item | sidebar + `[data-settings-panel-slug]` | muted default, themed hover |
| active navigation | previous selector + `[class~="bg-token-list-hover-background"]` | accent inset line and selected gradient |
| settings main | sidebar `+ [class~="relative"][class~="isolate"] > .main-surface` | image-backed full-page gradient |
| top draggable row | settings main + `> [class~="draggable"]` | translucent toolbar and separator |
| settings card | settings content + `[class~="rounded-2xl"][class~="border"][class~="border-token-border"]` | elevated glass card |
| row separators | settings content + `[class*="after:bg-token-border"] > :not(:last-child)::after` | accent-tinted rule |
| token buttons | `button[class~="bg-token-bg-fog"]`, `button[class~="bg-token-bg-primary"]`, `button[class~="bg-token-foreground/5"]` | panel fill, border, hover/open state |
| text inputs | `input:not([type="range"]):not([type="color"]), textarea, select` | dark fill, text, caret, border |
| switches | `button[role="switch"][data-state] > span` | accent gradient when checked, panel fill when unchecked |
| secondary text | `[class~="text-token-text-secondary"]` | `--ds-muted` |
| tables | `:is(table, thead, tbody, tr, [role="row"])` | themed border color |
| settings popups | `body:has(.app-shell-left-panel [data-settings-panel-slug]) :is([role="dialog"][data-state="open"], [data-slot="popover-content"], [role="listbox"])` | body-portal glass scoped to settings |

Prefix light counterparts with `html.codex-dream-skin[data-dream-shell="light"]`. Keep every settings selector scoped by `[data-settings-panel-slug]` so ordinary chat cards and dialogs are not accidentally recolored.

## Injector recognition

Settings can be the only visible renderer and has no composer. Keep both recognition paths in `scripts/injector.mjs`.

`probeSession()` must recognize either:

```text
normal = main.main-surface + aside.app-shell-left-panel + (composer or role=main)
settings = .app-shell-left-panel [data-settings-panel-slug] + div.main-surface
codex = normal OR settings
```

`verifySession()` must measure both settings nodes:

```text
settingsSidebar = .app-shell-left-panel:has([data-settings-panel-slug])
settingsSurface = settingsSidebar + relative.isolate > .main-surface
shellPass = (visible composer AND visible normal sidebar)
         OR (visible settings sidebar AND visible settings surface)
```

Do not restore the old unconditional composer/sidebar requirement; it makes successful settings injection report as failed. If Codex changes settings markup, update both `probeSession()` and `verifySession()` together, then add the new stable marker to `tests/run-tests.sh`.

## Hot apply

For theme-data-only changes, update the mutable theme and force one injection without editing source CSS:

```bash
/bin/bash -c '
  . ~/.codex/codex-dream-skin-studio/scripts/common-macos.sh
  ensure_state_root
  ensure_node_runtime
  port="$(state_field port 2>/dev/null || true)"
  [ -n "$port" ] || port=9341
  "$NODE" "$INJECTOR" --once --port "$port" --theme-dir "$THEME_DIR" --timeout-ms 8000
'
```

If CSS or injector logic changed, first synchronize only the changed engine files from the repo to `~/.codex/codex-dream-skin-studio`, restart the persistent injector job with the recorded port/theme directory, run `--once`, and rewrite `state.json` through helpers in `common-macos.sh`. Keep source and installed files byte-identical.

## Fallback DOM inspection

Only use this when a documented selector no longer matches:

1. Query `http://127.0.0.1:<port>/json/list` and choose the `app://-/index.html` page target.
2. Use CDP `Runtime.evaluate` to query roles, `data-*` attributes, token classes, rectangles, and `getComputedStyle()`.
3. Prefer stable markers in this order: explicit IDs and `data-slot`/`data-settings-panel-slug`/`data-app-shell-focus-area`; ARIA roles and states; exact token-class membership; structural relationships; tag names last.
4. Never key structural CSS to localized Chinese text, account names, or pixel coordinates.
5. Update this selector map in the same change whenever a selector changes.

Use screenshots only after DOM-based implementation to judge crop, contrast, blur, and visual balance.

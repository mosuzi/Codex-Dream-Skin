#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
NODE="${NODE:-/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node}"
[ -x "$NODE" ] || { printf 'Codex bundled Node.js was not found: %s\n' "$NODE" >&2; exit 1; }

while IFS= read -r file; do /bin/bash -n "$file"; done < <(
  /usr/bin/find "$ROOT" -type f \( -name '*.sh' -o -name '*.command' \) \
    ! -path '*/release/*' -print
)
while IFS= read -r file; do "$NODE" --check "$file" >/dev/null; done < <(
  /usr/bin/find "$ROOT/scripts" "$ROOT/assets" -type f \( -name '*.mjs' -o -name '*.js' \) -print
)

if /usr/bin/grep -R -n -E 'dream-skin-skin|DREAM_SKIN_SKIN|1\.0\.0-rc2' \
  "$ROOT/scripts" "$ROOT/assets" >/dev/null; then
  printf 'Legacy release-candidate identifiers remain in runtime files.\n' >&2
  exit 1
fi
for selector in \
  'section[role="dialog"][class~="bg-token-dropdown-background"]' \
  'data-app-shell-focus-area="right-panel"' \
  'data-app-shell-focus-area="bottom-panel"' \
  '[role="menu"][class~="bg-token-dropdown-background/90"]' \
  'data-settings-panel-slug' \
  'class~="max-h-[320px]"'; do
  if ! /usr/bin/grep -F -q "$selector" "$ROOT/assets/dream-skin.css"; then
    printf 'Required App Shell theme selector is missing: %s\n' "$selector" >&2
    exit 1
  fi
done
if ! /usr/bin/grep -F -q '[data-settings-panel-slug]' "$ROOT/scripts/injector.mjs"; then
  printf 'The injector does not recognize the settings renderer.\n' >&2
  exit 1
fi
if /usr/bin/grep -R -n -E '(writeFile|rename|copyFile|rm).*app\.asar' "$ROOT/scripts" >/dev/null; then
  printf 'A runtime script appears to mutate app.asar.\n' >&2
  exit 1
fi
if /usr/bin/grep -n -E '/usr/bin/python3|(^|[[:space:]])eval([[:space:]]|$)' \
  "$ROOT/scripts/common-macos.sh" >/dev/null; then
  printf 'The shared macOS runtime must parse state with the bundled Node.js, without python3 or eval.\n' >&2
  exit 1
fi

"$NODE" "$ROOT/scripts/injector.mjs" --check-payload >/dev/null

TMP="$(/usr/bin/mktemp -d /tmp/codex-dream-skin-tests.XXXXXX)"
trap '/bin/rm -rf "$TMP"' EXIT

RUNTIME_HOME="$TMP/runtime-home"
RUNTIME_STATE_ROOT="$RUNTIME_HOME/Library/Application Support/CodexDreamSkinStudio"
RUNTIME_STATE="$RUNTIME_STATE_ROOT/state.json"
STATE_EVAL_MARKER="$TMP/state-eval-marker"
EXPECTED_BUNDLE="/Applications/Codex \$(touch \"$STATE_EVAL_MARKER\").app"
EXPECTED_EXE="$EXPECTED_BUNDLE/Contents/MacOS/ChatGPT; touch \"$STATE_EVAL_MARKER\""
EXPECTED_VERSION='1.1.2 "nightly"'
EXPECTED_TEAM_ID="TEAM'ID"
/bin/mkdir -p "$RUNTIME_STATE_ROOT"
"$NODE" -e '
  const fs = require("node:fs");
  const [file, codexBundle, codexExe, codexVersion, codexTeamId] = process.argv.slice(1);
  fs.writeFileSync(file, `${JSON.stringify({ codexBundle, codexExe, codexVersion, codexTeamId })}\n`);
' "$RUNTIME_STATE" "$EXPECTED_BUNDLE" "$EXPECTED_EXE" "$EXPECTED_VERSION" "$EXPECTED_TEAM_ID"
/usr/bin/env -u NODE -u NODE_VERSION HOME="$RUNTIME_HOME" /bin/bash -c '
  . "$1/scripts/common-macos.sh"
  ensure_node_runtime
  [ "$CODEX_BUNDLE" = "$2" ]
  [ "$CODEX_EXE" = "$3" ]
  [ "$CODEX_VERSION" = "$4" ]
  [ "$CODEX_TEAM_ID" = "$5" ]
' _ "$ROOT" "$EXPECTED_BUNDLE" "$EXPECTED_EXE" "$EXPECTED_VERSION" "$EXPECTED_TEAM_ID"
[ ! -e "$STATE_EVAL_MARKER" ] || {
  printf 'Runtime state values were evaluated as shell code.\n' >&2
  exit 1
}

/bin/mkdir -p "$TMP/theme"
/bin/cp "$ROOT/assets/portal-hero.png" "$TMP/theme/background.png"
"$NODE" "$ROOT/scripts/write-theme.mjs" custom --output-dir "$TMP/theme" \
  --image background.png --name '测试主题' --tagline '测试口号' --quote 'TEST' \
  --accent '#11aa55' --secondary '#22bbcc' --highlight '#663399' >/dev/null
PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass || value.themeName !== "测试主题" || value.imageBytes < 1) process.exit(1);
' "$PAYLOAD_JSON"
/bin/mkdir -p "$TMP/missing-theme"
if MISSING_THEME_OUTPUT="$(
  "$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/missing-theme" 2>&1
)"; then
  printf 'Explicit theme directory without theme.json unexpectedly passed.\n' >&2
  exit 1
fi
/usr/bin/printf '%s\n' "$MISSING_THEME_OUTPUT" | /usr/bin/grep -F -q \
  "Explicit theme directory is missing theme.json: $TMP/missing-theme/theme.json"
"$NODE" "$ROOT/scripts/write-theme.mjs" reset-demo --output-dir "$TMP/theme" >/dev/null
RESET_PAYLOAD_JSON="$("$NODE" "$ROOT/scripts/injector.mjs" --check-payload --theme-dir "$TMP/theme")"
"$NODE" -e '
  const value = JSON.parse(process.argv[1]);
  if (!value.pass || value.themeName !== "Dream Skin" || value.imageBytes < 1) process.exit(1);
' "$RESET_PAYLOAD_JSON"
[ -f "$TMP/theme/theme.json" ]
[ -f "$TMP/theme/portal-hero.png" ]
[ ! -e "$TMP/theme/background.png" ]

CONFIG="$TMP/config.toml"
BACKUP="$TMP/theme-backup.json"
/usr/bin/printf '%s\n' \
  'model = "gpt-5"' \
  '' \
  '[desktop]' \
  'appearanceTheme = "system"' \
  'appearanceDarkCodeThemeId = "vscode-dark"' \
  'keepMe = true' > "$CONFIG"
/bin/cp "$CONFIG" "$TMP/original.toml"
"$NODE" "$ROOT/scripts/theme-config.mjs" install "$CONFIG" "$BACKUP" >/dev/null
/usr/bin/cmp -s "$CONFIG" "$TMP/original.toml"
"$NODE" -e '
  const backup = JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"));
  if (backup.values.appearanceTheme !== `appearanceTheme = "system"`) process.exit(1);
  if (backup.values.appearanceDarkCodeThemeId !== `appearanceDarkCodeThemeId = "vscode-dark"`) process.exit(1);
' "$BACKUP"
"$NODE" "$ROOT/scripts/theme-config.mjs" restore "$CONFIG" "$BACKUP" >/dev/null
/usr/bin/cmp -s "$CONFIG" "$TMP/original.toml"

NO_DESKTOP_CONFIG="$TMP/config-without-desktop.toml"
NO_DESKTOP_BACKUP="$TMP/theme-backup-without-desktop.json"
/usr/bin/printf '%s\n' 'model = "gpt-5"' 'keepMe = true' > "$NO_DESKTOP_CONFIG"
/bin/cp "$NO_DESKTOP_CONFIG" "$TMP/original-without-desktop.toml"
"$NODE" "$ROOT/scripts/theme-config.mjs" install "$NO_DESKTOP_CONFIG" "$NO_DESKTOP_BACKUP" >/dev/null
"$NODE" "$ROOT/scripts/theme-config.mjs" restore "$NO_DESKTOP_CONFIG" "$NO_DESKTOP_BACKUP" >/dev/null
/usr/bin/cmp -s "$NO_DESKTOP_CONFIG" "$TMP/original-without-desktop.toml"

INSTALL_HOME="$TMP/install-home"
INSTALL_CONFIG="$INSTALL_HOME/.codex/config.toml"
CODEX_APP_BUNDLE="${NODE%/Contents/Resources/cua_node/bin/node}"
/bin/mkdir -p "$(dirname "$INSTALL_CONFIG")"
/usr/bin/printf '%s\n' 'model = "gpt-5"' > "$INSTALL_CONFIG"
HOME="$INSTALL_HOME" CODEX_APP_BUNDLE="$CODEX_APP_BUNDLE" \
  "$ROOT/scripts/install-dream-skin-macos.sh" --no-launch --no-launchers >/dev/null
INSTALLED_ROOT="$INSTALL_HOME/.codex/codex-dream-skin-studio"
INSTALLED_THEME="$INSTALL_HOME/Library/Application Support/CodexDreamSkinStudio/theme"
[ -f "$INSTALLED_THEME/theme.json" ]
[ -f "$INSTALLED_THEME/portal-hero.png" ]
HOME="$INSTALL_HOME" CODEX_APP_BUNDLE="$CODEX_APP_BUNDLE" \
  "$INSTALLED_ROOT/scripts/doctor-macos.sh" >/dev/null

BROKEN_HOME="$TMP/broken-install-home"
BROKEN_CONFIG="$BROKEN_HOME/.codex/config.toml"
BROKEN_THEME="$BROKEN_HOME/Library/Application Support/CodexDreamSkinStudio/theme"
/bin/mkdir -p "$(dirname "$BROKEN_CONFIG")" "$BROKEN_THEME"
/usr/bin/printf '%s\n' 'model = "gpt-5"' > "$BROKEN_CONFIG"
if BROKEN_INSTALL_OUTPUT="$(
  HOME="$BROKEN_HOME" CODEX_APP_BUNDLE="$CODEX_APP_BUNDLE" \
    "$ROOT/scripts/install-dream-skin-macos.sh" --no-launch --no-launchers 2>&1
)"; then
  printf 'Clean-install initialization unexpectedly replaced an incomplete explicit theme directory.\n' >&2
  exit 1
fi
/usr/bin/printf '%s\n' "$BROKEN_INSTALL_OUTPUT" | /usr/bin/grep -F -q \
  "Explicit theme directory is missing theme.json: $BROKEN_THEME/theme.json"

/usr/bin/env -u HOME /bin/bash -c '. "$1/scripts/common-macos.sh"; [ -n "$HOME" ] && [ "$SKIN_VERSION" = "1.1.3" ]' _ "$ROOT"

printf 'PASS: syntax, payload, runtime-state safety, custom/reset themes, clean install, config round-trips, HOME recovery, signature, and doctor checks.\n'

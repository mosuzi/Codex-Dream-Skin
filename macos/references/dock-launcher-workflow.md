# Dock launcher workflow

Use this playbook to create or repair a distinct **Codex Dream Skin** Dock entry without modifying the official Codex/ChatGPT application bundle.

## Behavior contract

- The launcher is a small, separately signed app at `~/Applications/Codex Dream Skin.app`.
- It calls the installed engine at `~/.codex/codex-dream-skin-studio/scripts/start-dream-skin-macos.sh` with the verified loopback CDP port.
- It must use its own bundle identifier, `com.mosuzi.codex-dream-skin-launcher`; never reuse `com.openai.codex`.
- The launcher exits after apply/start succeeds. The persistent running process remains the official `/Applications/ChatGPT.app`, so the Dock running indicator ultimately appears under the official ChatGPT/Codex icon. A brief indicator under the launcher while its script runs is normal.
- Keep the launcher at the same path. Replacing or moving the app after pinning it can leave Dock with a stale file reference and a question-mark tile.

This design preserves the official app, signature, updater, bundle identity, and normal macOS process ownership.

## Build the launcher app

Set up the bundle and its unique identity:

```bash
APP="$HOME/Applications/Codex Dream Skin.app"
CONTENTS="$APP/Contents"
PLIST="$CONTENTS/Info.plist"

mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"
plutil -create xml1 "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDevelopmentRegion string en' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleDisplayName string Codex Dream Skin' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleExecutable string Codex Dream Skin' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIconFile string AppIcon' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleIdentifier string com.mosuzi.codex-dream-skin-launcher' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleInfoDictionaryVersion string 6.0' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleName string Codex Dream Skin' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundlePackageType string APPL' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleShortVersionString string 1.0.0' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :CFBundleVersion string 1' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :LSMinimumSystemVersion string 13.0' "$PLIST"
/usr/libexec/PlistBuddy -c 'Add :NSHighResolutionCapable bool true' "$PLIST"
```

Create `Contents/MacOS/Codex Dream Skin` with this payload and make it executable:

```bash
#!/bin/bash

set -u

STARTER="${HOME}/.codex/codex-dream-skin-studio/scripts/start-dream-skin-macos.sh"

if [ ! -x "$STARTER" ]; then
  /usr/bin/osascript -e 'display alert "Codex Dream Skin cannot start" message "The theme engine is missing. Reinstall Codex Dream Skin Studio." as critical'
  exit 1
fi

START_COMMAND=("$STARTER")
if [ "$(/usr/sbin/sysctl -in sysctl.proc_translated 2>/dev/null || true)" = "1" ]; then
  START_COMMAND=(/usr/bin/arch -arm64 /bin/bash "$STARTER")
fi

if ! "${START_COMMAND[@]}" --port 9341 --prompt-restart; then
  /usr/bin/osascript -e 'display alert "Codex Dream Skin failed" message "Check the CodexDreamSkinStudio logs under Library/Application Support." as critical'
  exit 1
fi
```

```bash
chmod 755 "$HOME/Applications/Codex Dream Skin.app/Contents/MacOS/Codex Dream Skin"
```

The native-architecture handoff matters when LaunchServices starts the wrapper through Rosetta: the engine's strict runtime check must still see the official app architecture.

## Prepare the distinct icon

Use a 1024 x 1024 RGBA PNG with a standard sRGB profile. A practical treatment is the official ChatGPT/Codex mark plus a small bottom-right moon or theme badge. Preserve the original rounded-square alpha mask so macOS does not render a white rectangle.

Generate a complete iconset from the prepared `AppIcon-source.png`:

```bash
APP="$HOME/Applications/Codex Dream Skin.app"
SOURCE="$APP/Contents/Resources/AppIcon-source.png"
ICONSET="/tmp/CodexDreamSkin.iconset"
SRGB='/System/Library/ColorSync/Profiles/sRGB Profile.icc'

mkdir -p "$ICONSET"
sips --matchTo "$SRGB" "$SOURCE" --out "$SOURCE"
sips -z 16 16 "$SOURCE" --out "$ICONSET/icon_16x16.png"
sips -z 32 32 "$SOURCE" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32 "$SOURCE" --out "$ICONSET/icon_32x32.png"
sips -z 64 64 "$SOURCE" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128 "$SOURCE" --out "$ICONSET/icon_128x128.png"
sips -z 256 256 "$SOURCE" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256 "$SOURCE" --out "$ICONSET/icon_256x256.png"
sips -z 512 512 "$SOURCE" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512 "$SOURCE" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$SOURCE" --out "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
```

When replacing an existing icon, edit the bundle in place and increment `CFBundleVersion`. Do not delete and recreate a launcher that is already pinned.

## Sign and register

Ad-hoc sign the complete launcher only after its executable, plist, and icon are final, then refresh LaunchServices:

```bash
APP="$HOME/Applications/Codex Dream Skin.app"
LSREGISTER='/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister'

codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
"$LSREGISTER" -f "$APP"
touch "$APP"
```

Any later change inside the app invalidates the signature. Re-sign before registering it again.

## Add the Dock tile

Remove any broken or duplicate **Codex Dream Skin** tile from Dock first. Add one fresh tile that points to the stable app path:

```bash
defaults write com.apple.dock persistent-apps -array-add \
  '<dict><key>tile-data</key><dict><key>bundle-identifier</key><string>com.mosuzi.codex-dream-skin-launcher</string><key>file-data</key><dict><key>_CFURLString</key><string>file://'$HOME'/Applications/Codex%20Dream%20Skin.app/</string><key>_CFURLStringType</key><integer>15</integer></dict><key>file-label</key><string>Codex Dream Skin</string><key>file-type</key><integer>41</integer></dict><key>tile-type</key><string>file-tile</string></dict>'
killall Dock
```

Dock may add its own bookmark and GUID fields after restart. Do not copy those opaque values between machines.

## Verification

Verify identity, signature, one Dock entry, and the exact file URL:

```bash
APP="$HOME/Applications/Codex Dream Skin.app"

/usr/bin/osascript -e 'id of app "Codex Dream Skin"'
codesign --verify --deep --strict "$APP"
defaults read com.apple.dock persistent-apps | \
  grep -A 20 -B 3 'com.mosuzi.codex-dream-skin-launcher'
curl --silent --show-error --max-time 2 http://127.0.0.1:9341/json/version
```

Expected results:

- AppleScript returns `com.mosuzi.codex-dream-skin-launcher`.
- Signature verification succeeds.
- Dock contains exactly one launcher tile with the URL `file://$HOME/Applications/Codex%20Dream%20Skin.app/` after shell expansion.
- Once Codex is running with the theme, the loopback CDP endpoint responds.
- Visual inspection shows the badged icon, not a question mark.
- After the launcher exits, the running indicator remains under the official ChatGPT/Codex icon.

## Repair a question-mark tile

A question mark normally means Dock can no longer resolve the file reference it saved, or is using stale LaunchServices/icon cache state after a bundle update. Moving or atomically replacing a pinned launcher raises that risk. In the observed recovery, the launcher still existed and its signature and icon were valid; because the old tile had already been removed, its exact saved metadata was unavailable. Re-registering the current bundle and adding a fresh tile repaired the problem.

1. Confirm that `~/Applications/Codex Dream Skin.app` exists and that its executable and `AppIcon.icns` are present.
2. Verify the signature. If the bundle was edited, increment `CFBundleVersion`, re-sign it, and register it again.
3. Remove the question-mark tile from Dock; do not reset the entire Dock preference domain.
4. Re-run the **Add the Dock tile** command and restart Dock.
5. Verify the live icon and restore the user's original Dock auto-hide setting if it was temporarily changed for visual QA.

This is a launcher-reference repair. It does not require changing the theme, injector, official app, or Codex data.

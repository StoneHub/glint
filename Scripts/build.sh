#!/bin/zsh
# Build the app bundle (M↓.app) from the Swift package (no Xcode project needed).
#
#   Scripts/build.sh            build  → build/M↓.app
#   Scripts/build.sh install    build, copy to ~/Applications, register with Launch Services
#   Scripts/build.sh run [file] build and open (optionally with a file)
#   Scripts/build.sh icon       regenerate build/AppIcon.icns
#   Scripts/build.sh quicklook  build, then add the Quick Look extension (needs Xcode and XcodeGen)
#
# Nothing here deletes recursively; bundles are overwritten in place with ditto.
# To start fresh: delete build/ and .build/ yourself.
set -euo pipefail
cd "$(dirname "$0")/.."

APP=MDown          # executable and SwiftPM product
BUNDLE_NAME="M↓"   # the folder carries the display name, like the Dock and the menu bar
BUILD=build
CONF=${CONF:-release}
BUNDLE="$BUILD/$BUNDLE_NAME.app"
PLUGINS="$BUNDLE/Contents/PlugIns"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

icon() {
  if [[ ! -f "$BUILD/AppIcon.icns" || Scripts/make-icon.swift -nt "$BUILD/AppIcon.icns" ]]; then
    swift Scripts/make-icon.swift "$BUILD/AppIcon.iconset"
    iconutil -c icns "$BUILD/AppIcon.iconset" -o "$BUILD/AppIcon.icns"
  fi
}

build() {
  swift build -c "$CONF"
  mkdir -p "$BUILD"
  icon
  local bin
  bin="$(swift build -c "$CONF" --show-bin-path)/$APP"
  mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"
  cp "$bin" "$BUNDLE/Contents/MacOS/$APP"
  cp Resources/Info.plist "$BUNDLE/Contents/Info.plist"
  cp "$BUILD/AppIcon.icns" "$BUNDLE/Contents/Resources/AppIcon.icns"
  printf 'APPL????' > "$BUNDLE/Contents/PkgInfo"
  codesign --force --sign - "$BUNDLE"
  echo "built $BUNDLE"
}

# A plain build leaves an earlier 'quicklook' extension in place (nothing here deletes); say so.
note_kept_extension() {
  if [[ -d "$PLUGINS" ]]; then
    echo "kept the Quick Look extension from an earlier 'quicklook' build (plain 'build' does not rebuild it)"
  fi
}

# The extension is an Xcode app-extension target; XcodeGen writes MDown.xcodeproj (gitignored)
# from project.yml, xcodebuild produces the ad-hoc-signed .appex, and it is embedded in the
# package-built app. The app is then re-signed over the already-signed extension.
quicklook() {
  build
  xcodegen generate --spec project.yml
  xcodebuild -project "$APP.xcodeproj" -scheme MDownQuickLook -configuration Release \
    -destination "platform=macOS" -derivedDataPath "$BUILD/DerivedData" -quiet build
  mkdir -p "$PLUGINS"
  ditto "$BUILD/DerivedData/Build/Products/Release/MDownQuickLook.appex" "$PLUGINS/MDownQuickLook.appex"
  codesign --force --sign - "$BUNDLE"
  echo "embedded $PLUGINS/MDownQuickLook.appex"
}

install() {
  build
  note_kept_extension
  local dest="$HOME/Applications/$BUNDLE_NAME.app"
  mkdir -p "$HOME/Applications"
  ditto "$BUNDLE" "$dest"
  "$LSREGISTER" -f "$dest"
  # Spotlight matches an app by its file name, and M↓ has no key to type. It also indexes Finder
  # comments, so this one lets "mdown" find the app.
  xattr -w com.apple.metadata:kMDItemFinderComment \
    '<?xml version="1.0" encoding="UTF-8"?><plist version="1.0"><string>mdown · M↓ Markdown viewer and editor</string></plist>' "$dest"
  mdimport "$dest"
  if [[ -d "$dest/Contents/PlugIns/MDownQuickLook.appex" ]]; then
    pluginkit -a "$dest/Contents/PlugIns/MDownQuickLook.appex"
    echo "registered the Quick Look extension; try: qlmanage -p README.md"
  fi
  echo "installed $dest (Spotlight: type mdown)"
  echo "To make it the default opener: M↓ menu → “Make M↓ the Default for Markdown & Text…”"
}

case "${1:-build}" in
  build)     build; note_kept_extension ;;
  quicklook) quicklook ;;
  install)   install ;;
  run)       build; note_kept_extension; shift; open -a "$PWD/$BUNDLE" "$@" ;;
  icon)      rm -f "$BUILD/AppIcon.icns"; icon ;;
  *)         echo "usage: $0 [build|quicklook|install|run [file]|icon]" >&2; exit 2 ;;
esac

#!/bin/zsh
# Build Glint.app from the Swift package (no Xcode project needed).
#
#   Scripts/build.sh            build  → build/Glint.app
#   Scripts/build.sh install    build, copy to ~/Applications, register with Launch Services
#   Scripts/build.sh run [file] build and open (optionally with a file)
#   Scripts/build.sh icon       regenerate build/AppIcon.icns
#
# Nothing here deletes recursively; bundles are overwritten in place with ditto.
# To start fresh: delete build/ and .build/ yourself.
set -euo pipefail
cd "$(dirname "$0")/.."

APP=Glint
BUILD=build
CONF=${CONF:-release}
BUNDLE="$BUILD/$APP.app"
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

install() {
  build
  local dest="$HOME/Applications/$APP.app"
  mkdir -p "$HOME/Applications"
  ditto "$BUNDLE" "$dest"
  "$LSREGISTER" -f "$dest"
  echo "installed $dest"
  echo "To make it the default opener: Glint menu → “Make Glint the Default for Markdown & Text…”"
}

case "${1:-build}" in
  build)   build ;;
  install) install ;;
  run)     build; shift; open -a "$PWD/$BUNDLE" "$@" ;;
  icon)    rm -f "$BUILD/AppIcon.icns"; icon ;;
  *)       echo "usage: $0 [build|install|run [file]|icon]" >&2; exit 2 ;;
esac

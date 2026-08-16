#!/usr/bin/env bash
# Build Netlify : un site = l'app web, l'autre = l'admin.
# SITE_TARGET=app   (défaut)  → copie web de l'application
# SITE_TARGET=admin           → panneau d'administration
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TARGET="$(echo "${SITE_TARGET:-app}" | tr '[:upper:]' '[:lower:]')"
PUBLISH_DIR="build/web_deploy"
FLUTTER_DIR="${FLUTTER_ROOT:-$ROOT/.flutter-sdk}"

echo "=== B-Place Netlify build (SITE_TARGET=$TARGET) ==="

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Installation de Flutter (stable)..."
  rm -rf "$FLUTTER_DIR"
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"
flutter config --no-analytics --enable-web
flutter pub get

restore_web_shell() {
  if [ -f web/index.html.bak ]; then
    mv -f web/index.html.bak web/index.html
  fi
  if [ -f web/manifest.json.bak ]; then
    mv -f web/manifest.json.bak web/manifest.json
  fi
}

if [ "$TARGET" = "admin" ]; then
  echo "Build plateforme admin..."
  cp web/index.html web/index.html.bak
  cp web/manifest.json web/manifest.json.bak
  cp web_admin/index.html web/index.html
  cp web_admin/manifest.json web/manifest.json
  trap restore_web_shell EXIT
  flutter build web -t lib/admin_main.dart --release --no-wasm-dry-run --output "$PUBLISH_DIR"
else
  echo "Build app web (copie mobile)..."
  flutter build web -t lib/main.dart --release --no-wasm-dry-run --output "$PUBLISH_DIR"
fi

echo "OK → $PUBLISH_DIR"

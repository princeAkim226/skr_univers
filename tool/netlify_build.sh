#!/usr/bin/env bash
# Build Netlify : un site = l'app web, l'autre = l'admin.
# SITE_TARGET=app   (défaut)  → copie web de l'application
# SITE_TARGET=admin           → panneau d'administration
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

RAW_TARGET="$(printf '%s' "${SITE_TARGET:-}" | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]')"
SITE_NAME="$(printf '%s' "${NETLIFY_SITE_NAME:-}" | tr '[:upper:]' '[:lower:]')"

if [ "$RAW_TARGET" = "admin" ] || [ "$RAW_TARGET" = "administration" ] || [[ "$SITE_NAME" == *admin* ]]; then
  TARGET="admin"
else
  TARGET="app"
fi

PUBLISH_DIR="build/web_deploy"
FLUTTER_DIR="${FLUTTER_ROOT:-$ROOT/.flutter-sdk}"

echo "=== B-Place Netlify build ==="
echo "SITE_TARGET brut : '${SITE_TARGET:-<vide>}'"
echo "NETLIFY_SITE_NAME : '${NETLIFY_SITE_NAME:-<vide>}'"
echo "Plateforme        : $TARGET"

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

  echo "Ajout page + APK sur le site app (/apk)..."
  mkdir -p "$PUBLISH_DIR/apk"
  cp apk_site/index.html "$PUBLISH_DIR/apk/index.html"
  if [ -f apk_site/business-place-release.apk ]; then
    cp apk_site/business-place-release.apk "$PUBLISH_DIR/apk/business-place-release.apk"
    echo "APK inclus ($(du -h apk_site/business-place-release.apk | cut -f1))"
  else
    echo "ATTENTION: apk_site/business-place-release.apk introuvable"
  fi
fi

echo "OK → $PUBLISH_DIR"

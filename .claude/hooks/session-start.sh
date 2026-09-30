#!/usr/bin/env bash
# SessionStart hook for Claude Code on the web: installs the Flutter version pinned in .fvmrc
# and the Dart dependencies, so analyze / test / build work in cloud sessions.
# Does nothing on a local machine (fvm is used there).
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(dirname "$0")/../..}"

FLUTTER_VERSION="$(sed -n 's/.*"flutter"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' .fvmrc)"
FLUTTER_DIR="$HOME/flutter-sdk"
BIN_DIR="$HOME/.local/bin"

installed_version() {
  git -C "$FLUTTER_DIR" describe --tags --exact-match 2>/dev/null || true
}

if [ "$(installed_version)" != "$FLUTTER_VERSION" ]; then
  rm -rf "$FLUTTER_DIR"
  echo "Installing Flutter $FLUTTER_VERSION into $FLUTTER_DIR"
  git clone --quiet --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

# Minimal fvm stand-in so the documented `fvm flutter ...` / `fvm dart ...` commands work as is.
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/fvm" <<'SHIM'
#!/usr/bin/env bash
# fvm stand-in for cloud sessions: the pinned SDK is already on PATH.
case "${1:-}" in
  install|use) exit 0 ;;
  *) exec "$@" ;;
esac
SHIM
chmod +x "$BIN_DIR/fvm"

export PATH="$FLUTTER_DIR/bin:$BIN_DIR:$PATH"
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$FLUTTER_DIR/bin:$BIN_DIR:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

flutter --disable-analytics >/dev/null
flutter precache --web
flutter pub get

#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_ROOT"

source "$REPO_ROOT/bin/activate-hermit"

HOST_TARGET=$(rustc -vV | sed -n 's|host: ||p')
TARGET=${1:-$HOST_TARGET}

case "$TARGET" in
    aarch64-apple-darwin|x86_64-apple-darwin) ;;
    *)
        echo "Error: Buzz LYPES desktop builds currently support macOS targets only." >&2
        echo "Received target: $TARGET" >&2
        exit 1
        ;;
esac

export CARGO_TARGET_DIR="$REPO_ROOT/target/lypes"

echo "Installing locked JavaScript dependencies..."
pnpm install --frozen-lockfile

echo "Building release sidecars for $TARGET..."
cargo build \
    --release \
    --target "$TARGET" \
    -p buzz-acp \
    -p buzz-agent \
    -p buzz-dev-mcp \
    -p git-credential-nostr \
    -p buzz-cli

BINARIES_DIR="$REPO_ROOT/desktop/src-tauri/binaries"
SIDECAR_SOURCE="$CARGO_TARGET_DIR/$TARGET/release"
mkdir -p "$BINARIES_DIR"

for binary in buzz-acp buzz-agent buzz-dev-mcp git-credential-nostr buzz; do
    source_path="$SIDECAR_SOURCE/$binary"
    destination="$BINARIES_DIR/$binary-$TARGET"

    if [[ ! -f "$source_path" ]]; then
        echo "Error: missing release sidecar $source_path" >&2
        exit 1
    fi

    cp "$source_path" "$destination"
    chmod 755 "$destination"
done

echo "Building unsigned Buzz LYPES app and DMG..."
cd "$REPO_ROOT/desktop"
if [[ "${BUZZ_LYPES_MESH:-0}" == "1" ]]; then
    TAURI_BUNDLER_DMG_IGNORE_CI=true pnpm tauri build \
        --verbose \
        --no-sign \
        --target "$TARGET" \
        --bundles app,dmg \
        --config src-tauri/tauri.lypes.conf.json \
        --features mesh-llm
else
    TAURI_BUNDLER_DMG_IGNORE_CI=true pnpm tauri build \
        --verbose \
        --no-sign \
        --target "$TARGET" \
        --bundles app,dmg \
        --config src-tauri/tauri.lypes.conf.json
fi

ARTIFACT_DIR="$CARGO_TARGET_DIR/$TARGET/release/bundle"
echo "Buzz LYPES artifacts:"
find "$ARTIFACT_DIR" -maxdepth 3 -type f \( -name "*.dmg" -o -name "*.app.tar.gz" \) -print
find "$ARTIFACT_DIR" -maxdepth 2 -type d -name "*.app" -print

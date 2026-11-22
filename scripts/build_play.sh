#!/usr/bin/env bash
# Play AAB του Floanta Support. Γράφει μόνο σε αυτό το δέντρο, στο
# CARGO_TARGET_DIR και στο /home/alex/src/floanta-support-dist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FLUTTER_TREE="$ROOT"

SERVER_ENV="$ROOT/config/server.env"
if [[ ! -f "$SERVER_ENV" ]]; then
    echo "Λείπει το config/server.env" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "$SERVER_ENV"
ID_SERVER="${ID_SERVER:-}"
PUBLIC_KEY="${PUBLIC_KEY:-}"
if [[ -z "$ID_SERVER" || -z "$PUBLIC_KEY" ]]; then
    echo "Συμπλήρωσε ID_SERVER και PUBLIC_KEY στο config/server.env." >&2
    exit 1
fi

python3 - "$ROOT" "$ID_SERVER" "$PUBLIC_KEY" <<'PY'
import json, sys
root, host, key = sys.argv[1], sys.argv[2].strip(), sys.argv[3].strip()
path = root + "/flutter/android/app/src/main/assets/floanta_server.json"
with open(path, "w", encoding="utf-8") as f:
    json.dump({"host": host, "key": key}, f, ensure_ascii=False)
    f.write("\n")
print("Server:", host)
PY

export CARGO_BUILD_JOBS=3
export CARGO_NET_GIT_FETCH_WITH_CLI=false
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/alex/Android/Sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    ANDROID_NDK_HOME="$(find "$ANDROID_SDK_ROOT/ndk" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)"
fi
export ANDROID_NDK_HOME
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
export VCPKG_ROOT="${VCPKG_ROOT:-/home/alex/src/vcpkg}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/home/alex/src/floanta-rustdesk-target}"
FLUTTER_ROOT="${FLUTTER_ROOT:-/home/alex/src/flutter-3.24.5}"
export PATH="$FLUTTER_ROOT/bin:${HOME}/.cargo/bin:${PATH}"

mkdir -p "$ROOT/flutter/android"
cat > "$ROOT/flutter/android/local.properties" <<EOF
sdk.dir=$ANDROID_SDK_ROOT
flutter.sdk=$FLUTTER_ROOT
floanta.play=true
EOF

JNI_DIR="$ROOT/flutter/android/app/src/main/jniLibs/arm64-v8a"
SO="$JNI_DIR/librustdesk.so"
if [[ ! -f "$SO" ]]; then
    SRC="$CARGO_TARGET_DIR/aarch64-linux-android/release/liblibrustdesk.so"
    if [[ ! -f "$SRC" ]]; then
        echo "Λείπει το librustdesk.so και δεν ξεκινάει cargo build." >&2
        exit 1
    fi
    mkdir -p "$JNI_DIR"
    cp "$SRC" "$SO"
    cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
        "$JNI_DIR/"
fi

cd "$FLUTTER_TREE/flutter"
nice -n 19 flutter pub get
nice -n 19 flutter build appbundle --release \
    --target-platform android-arm64 \
    --dart-define=FLOANTA_PLAY=true \
    --android-project-arg=floantaPlay=true

VER="$(awk '/^version:/{print $2}' pubspec.yaml | cut -d+ -f1)"
DEST_DIR="/home/alex/src/floanta-support-dist"
mkdir -p "$DEST_DIR"
cp "$FLUTTER_TREE/flutter/build/app/outputs/bundle/release/app-release.aab" \
    "$DEST_DIR/Floanta-Support-${VER}-play.aab"
echo "AAB: $DEST_DIR/Floanta-Support-${VER}-play.aab"

#!/usr/bin/env bash
# Δικό του build του Floanta Desk (RustDesk 1.5.3 + οι δικές μας αλλαγές).
# Βγάζει APK arm64, υπογεγραμμένο με το keystore αυτού του φακέλου.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

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
    echo "Συμπλήρωσε ID_SERVER και PUBLIC_KEY στο config/server.env. Χωρίς αυτά δεν βγαίνει APK." >&2
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

# Το git του workspace είναι κλειστό. Οι εξαρτήσεις κατεβαίνουν με το libgit2 του Cargo.
export CARGO_NET_GIT_FETCH_WITH_CLI=false
# Το hwcodec τρέχει bindgen και θέλει libclang (πακέτο libclang-dev).
export LIBCLANG_PATH="${LIBCLANG_PATH:-/usr/lib/llvm-18/lib}"
if [[ ! -e "$LIBCLANG_PATH/libclang.so" ]]; then
    echo "Λείπει το libclang στο $LIBCLANG_PATH" >&2
    exit 1
fi
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-/home/alex/Android/Sdk}"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
if [[ -z "${ANDROID_NDK_HOME:-}" ]]; then
    ANDROID_NDK_HOME="$(find "$ANDROID_SDK_ROOT/ndk" -mindepth 1 -maxdepth 1 -type d | sort | tail -1)"
fi
export ANDROID_NDK_HOME
export ANDROID_NDK_ROOT="$ANDROID_NDK_HOME"
export VCPKG_ROOT="${VCPKG_ROOT:-/home/alex/src/vcpkg}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-/home/alex/src/floanta-rustdesk-target}"
# Το Android build του RustDesk 1.5.3 είναι για Flutter 3.24.5. Το 3.44 σπάει το Dart.
if [[ -z "${FLUTTER_ROOT:-}" && -x /home/alex/src/flutter-3.24.5/bin/flutter ]]; then
    FLUTTER_ROOT=/home/alex/src/flutter-3.24.5
fi
FLUTTER_ROOT="${FLUTTER_ROOT:-/home/alex/flutter}"
export PATH="$FLUTTER_ROOT/bin:$PATH"

if [[ ! -x "$VCPKG_ROOT/vcpkg" ]]; then
    echo "Λείπει το vcpkg στο $VCPKG_ROOT" >&2
    exit 1
fi

mkdir -p "$ROOT/flutter/android"
cat > "$ROOT/flutter/android/local.properties" <<EOF
sdk.dir=$ANDROID_SDK_ROOT
flutter.sdk=$FLUTTER_ROOT
EOF

SIGN_DIR="$ROOT/signing"
mkdir -p "$SIGN_DIR"
KEYSTORE="$SIGN_DIR/floanta-desk.jks"
PROPS="$ROOT/flutter/android/key.properties"
if [[ ! -f "$KEYSTORE" ]]; then
    PASS="$(openssl rand -base64 24 | tr -d '\n')"
    keytool -genkeypair -keystore "$KEYSTORE" -alias floanta-desk -keyalg RSA -keysize 2048 -validity 10000 \
        -storepass "$PASS" -keypass "$PASS" -dname "CN=Floanta Desk, O=ETTC SCE LTD, C=GR"
    cat > "$PROPS" <<EOF
storePassword=$PASS
keyPassword=$PASS
keyAlias=floanta-desk
storeFile=$KEYSTORE
EOF
    chmod 600 "$PROPS" "$KEYSTORE"
    echo "Νέο keystore: $KEYSTORE"
    echo "Μην το σβήσεις. Χωρίς το ίδιο keystore το Android δεν περνάει ενημέρωση από πάνω."
fi

if ! command -v cargo >/dev/null; then
    echo "Λείπει το cargo. Εγκατάστησε rustup και ξανατρέξε το build." >&2
    exit 1
fi
if ! cargo ndk --version >/dev/null 2>&1; then
    cargo install cargo-ndk --version 3.1.2 --locked
fi
rustup target add aarch64-linux-android

if ! command -v flutter_rust_bridge_codegen >/dev/null; then
    cargo install flutter_rust_bridge_codegen --version 1.80.1 --features uuid --locked
fi

# Το Flutter κατεβάζει πακέτα με git. Μέσα στο κλειδωμένο workspace το git αρνείται,
# οπότε το pub και το APK χτίζονται σε αντίγραφο έξω από αυτό.
FLUTTER_TREE="$ROOT"
if ! git --version >/dev/null 2>&1; then
    FLUTTER_TREE="/home/alex/src/floanta-desk-build"
fi
sync_flutter_tree() {
    if [[ "$FLUTTER_TREE" == "$ROOT" ]]; then
        return
    fi
    mkdir -p "$FLUTTER_TREE"
    rsync -a --delete \
        --exclude flutter/build \
        --exclude dist \
        "$ROOT/" "$FLUTTER_TREE/"
}

if [[ ! -f "$ROOT/src/bridge_generated.rs" || ! -f "$ROOT/flutter/lib/generated_bridge.dart" || ! -f "$ROOT/flutter/lib/generated_bridge.freezed.dart" ]]; then
    sync_flutter_tree
    (cd "$FLUTTER_TREE/flutter" && flutter pub get)
    mkdir -p "$FLUTTER_TREE/flutter/macos/Runner" "$FLUTTER_TREE/flutter/ios/Runner"
    (
        cd "$FLUTTER_TREE"
        flutter_rust_bridge_codegen \
            --rust-input ./src/flutter_ffi.rs \
            --dart-output ./flutter/lib/generated_bridge.dart \
            --c-output ./flutter/macos/Runner/bridge_generated.h \
            --llvm-path "$LIBCLANG_PATH/libclang.so"
        cp ./flutter/macos/Runner/bridge_generated.h ./flutter/ios/Runner/bridge_generated.h
    )
    if [[ "$FLUTTER_TREE" != "$ROOT" ]]; then
        cp "$FLUTTER_TREE/src/bridge_generated.rs" "$FLUTTER_TREE/src/bridge_generated.io.rs" "$ROOT/src/"
        cp "$FLUTTER_TREE/flutter/lib/generated_bridge.dart" "$FLUTTER_TREE/flutter/lib/generated_bridge.freezed.dart" "$ROOT/flutter/lib/"
        cp "$FLUTTER_TREE/flutter/macos/Runner/bridge_generated.h" "$ROOT/flutter/macos/Runner/" 2>/dev/null || true
        cp "$FLUTTER_TREE/flutter/ios/Runner/bridge_generated.h" "$ROOT/flutter/ios/Runner/" 2>/dev/null || true
    fi
fi

bash "$ROOT/flutter/build_android_deps.sh" arm64-v8a

cargo ndk --platform 21 --target aarch64-linux-android --bindgen build --locked --release --features flutter,hwcodec
mkdir -p "$ROOT/flutter/android/app/src/main/jniLibs/arm64-v8a"
cp "$CARGO_TARGET_DIR/aarch64-linux-android/release/liblibrustdesk.so" \
    "$ROOT/flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so"
cp "$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so" \
    "$ROOT/flutter/android/app/src/main/jniLibs/arm64-v8a/"
"$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip" \
    "$ROOT/flutter/android/app/src/main/jniLibs/arm64-v8a/"/* || true

sync_flutter_tree
cd "$FLUTTER_TREE/flutter"
flutter pub get
flutter build apk --release --target-platform android-arm64 --split-per-abi

VER="$(awk '/^version:/{print $2}' pubspec.yaml | cut -d+ -f1)"
mkdir -p "$ROOT/dist"
cp "$FLUTTER_TREE/flutter/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk" \
    "$ROOT/dist/Floanta-Desk-${VER}.apk"
echo "APK: $ROOT/dist/Floanta-Desk-${VER}.apk"

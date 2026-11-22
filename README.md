# Floanta Support

Floanta Support is an Android remote-support app made by New Age Software Inc. / ETTC for eshopservices.gr customers. A technician can see the customer's screen and, if the customer allows it, control the phone during a support session.

It is a modified version of **RustDesk 1.5.3** (https://github.com/rustdesk/rustdesk), © RustDesk contributors, licensed under the **GNU AGPL-3.0** (see `LICENCE`). This repository has the complete source of our modified version, as the AGPL requires. Our changes are listed in `NOTICE.md`.

- Android applicationId: `floanta.support`
- Version: 0.1.0 (versionCode 1)
- ID/rendezvous server: `supportservice.floanta.com` (set in `config/server.env` and `flutter/android/app/src/main/assets/floanta_server.json`)

## Build

- Play build (AAB, arm64): `scripts/build_play.sh`
- Sideload APK build: `scripts/build.sh`

Both scripts expect Flutter 3.24.5, the Android SDK/NDK, Rust with `cargo-ndk`, and vcpkg. Their default paths can be changed with environment variables (`FLUTTER_ROOT`, `ANDROID_SDK_ROOT`, `VCPKG_ROOT`, `CARGO_TARGET_DIR`). Signing keys are not in this repository; provide your own `key.properties` and keystore.

The upstream RustDesk README, with general build steps, is here: https://github.com/rustdesk/rustdesk/blob/1.5.3/README.md

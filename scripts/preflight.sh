#!/usr/bin/env bash
set -euo pipefail
printf '=== FluxNet preflight ===\n'
for f in android/settings.gradle android/app/build.gradle android/build.gradle android/gradle/wrapper/gradle-wrapper.properties pubspec.yaml; do test -f "$f" || { echo "MISSING $f"; exit 21; }; done
if find android -name build.gradle.kts | grep -q .; then echo 'ERROR: duplicate Kotlin DSL Gradle files detected'; find android -name build.gradle.kts; exit 22; fi
if grep -R -nE 'jcenter\(|device_apps:|flutter_vpn_service:' android pubspec.yaml | grep 'jcenter('; then echo 'ERROR: obsolete jcenter'; exit 23; fi
printf 'Versions: '; grep -E 'com.android.application.*version|org.jetbrains.kotlin.android.*version' android/settings.gradle || true
printf 'Gradle: '; grep distributionUrl android/gradle/wrapper/gradle-wrapper.properties
flutter --version
flutter pub get
flutter analyze --no-fatal-infos

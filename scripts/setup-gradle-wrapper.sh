#!/usr/bin/env bash
# Setup gradle wrapper for offline-first Flutter project.
# Run this ONCE locally after cloning, before `flutter build apk`.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WRAPPER_DIR="$PROJECT_DIR/android/gradle/wrapper"
WRAPPER_JAR="$WRAPPER_DIR/gradle-wrapper.jar"
WRAPPER_PROPS="$WRAPPER_DIR/gradle-wrapper.properties"

mkdir -p "$WRAPPER_DIR"

# gradle-wrapper.properties
cat > "$WRAPPER_PROPS" <<'PROPS'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
distributionSha256Sum=544c35d6bd849ae8a5ed0bcea39ba677dc40f49df757157decbfddd2c4b0b8a6
PROPS

# gradle-wrapper.jar (binary — fetched from upstream Gradle tag)
if [ ! -f "$WRAPPER_JAR" ]; then
  echo "↓ Downloading gradle-wrapper.jar (Gradle 8.7)..."
  curl -fsSL -o "$WRAPPER_JAR" \
    https://raw.githubusercontent.com/gradle/gradle/v8.7.0/gradle/wrapper/gradle-wrapper.jar
  echo "✓ gradle-wrapper.jar saved"
else
  echo "✓ gradle-wrapper.jar already exists"
fi

# gradlew script (POSIX sh)
cat > "$PROJECT_DIR/android/gradlew" <<'GRADLEW'
#!/bin/sh
DIR="$(cd "$(dirname "$0")" && pwd)"
APP_HOME="$DIR"
CLASSPATH="$APP_HOME/gradle/wrapper/gradle-wrapper.jar"
exec java -classpath "$CLASSPATH" org.gradle.wrapper.GradleWrapperMain "$@"
GRADLEW
chmod +x "$PROJECT_DIR/android/gradlew"

# gradlew.bat (Windows)
cat > "$PROJECT_DIR/android/gradlew.bat" <<'BAT'
@if "%DEBUG%"=="" @echo off
setlocal
set DIR=%~dp0
set APP_HOME=%DIR%
set CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar
java -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
BAT

echo ""
echo "✅ Gradle wrapper ready."
echo "   Next steps:"
echo "   1. flutter pub get"
echo "   2. dart run build_runner build --delete-conflicting-outputs"
echo "   3. flutter build apk --release"

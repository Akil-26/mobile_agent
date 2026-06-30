#!/bin/bash
set -e

# Builds libllama.so for Android (arm64-v8a) so llama_cpp_dart has a real
# native library to load. Run this once before `flutter run` on Android.
#
# Requires:
#   - ANDROID_NDK_HOME (or ANDROID_NDK env var) pointing at an installed NDK
#     e.g. export ANDROID_NDK_HOME=$HOME/Library/Android/sdk/ndk/27.0.12077973
#   - cmake and a C/C++ toolchain
#   - git (to fetch llama.cpp source)

NDK_PATH="${ANDROID_NDK_HOME:-${ANDROID_NDK:-}}"
if [ -z "$NDK_PATH" ]; then
  echo "❌ Set ANDROID_NDK_HOME (or ANDROID_NDK) to your Android NDK path first."
  echo "   e.g. export ANDROID_NDK_HOME=\$HOME/Library/Android/sdk/ndk/27.0.12077973"
  exit 1
fi

PROJECT_ROOT="$(pwd)"
LLAMA_SRC="${LLAMA_SRC:-/tmp/llama_cpp_src}"
OUTPUT_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs/arm64-v8a"

mkdir -p "$OUTPUT_DIR"

if [ ! -d "$LLAMA_SRC" ]; then
  echo "📥 Cloning llama.cpp into $LLAMA_SRC ..."
  git clone --depth 1 https://github.com/ggml-org/llama.cpp "$LLAMA_SRC"
fi

cd "$LLAMA_SRC"
rm -rf build-android
mkdir -p build-android
cd build-android

cmake \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_LLAMAFILE=OFF \
    ..

cmake --build . --target llama -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)"

# The exact output path varies slightly between llama.cpp versions; find it.
SO_FILE=$(find . -name "libllama.so" | head -n 1)
if [ -z "$SO_FILE" ]; then
  echo "❌ Build finished but libllama.so wasn't found. Check the cmake/build output above."
  exit 1
fi

cp "$SO_FILE" "$OUTPUT_DIR/"
echo "✅ libllama.so built and copied to: $OUTPUT_DIR"
echo "   Now run: flutter pub get && flutter run"

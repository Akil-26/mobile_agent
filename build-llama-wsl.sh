#!/bin/bash
set -e

NDK_PATH="/mnt/c/Android/Sdk/ndk/27.0.12077973"
CMAKE_BIN="/mnt/c/Android/Sdk/cmake/3.22.1/bin/cmake"
LLAMA_SRC="/tmp/llama_cpp_src"
OUTPUT_DIR="/mnt/c/projects/Mobile_apps/Mobile_agent/android/app/src/main/jniLibs/arm64-v8a"

mkdir -p "$OUTPUT_DIR"

if [ ! -d "$LLAMA_SRC" ]; then
  echo "📥 Cloning llama.cpp..."
  git clone --depth 1 https://github.com/ggml-org/llama.cpp "$LLAMA_SRC"
fi

cd "$LLAMA_SRC"
rm -rf build-android
mkdir -p build-android
cd build-android

echo "🔨 Running cmake configure..."
"$CMAKE_BIN" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DGGML_LLAMAFILE=OFF \
    -DCMAKE_MAKE_PROGRAM=make \
    -G "Unix Makefiles" \
    ..

echo "🔨 Building libllama.so..."
"$CMAKE_BIN" --build . --target llama -j"$(nproc)"

SO_FILE=$(find . -name "libllama.so" | head -n 1)
if [ -z "$SO_FILE" ]; then
  echo "❌ libllama.so not found after build"
  exit 1
fi

cp "$SO_FILE" "$OUTPUT_DIR/"
ls -la "$OUTPUT_DIR/libllama.so"
echo "✅ libllama.so built and copied to: $OUTPUT_DIR"

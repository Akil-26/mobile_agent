#!/bin/bash

# Build llama.cpp for Android ARM64

ANDROID_NDK="/Android/SDK/ndk/27.0.12077973"
LLAMA_SRC="/tmp/llama_build"
OUTPUT_DIR="$(pwd)/android/app/src/main/jniLibs/arm64-v8a"

mkdir -p "$OUTPUT_DIR"

# Compile with NDK
cd "$LLAMA_SRC"

# Configure and build with CMake
mkdir -p build-android
cd build-android

cmake \
    -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DLLAMA_NATIVE=OFF \
    ..

make -j$(nproc) llama

# Copy to Flutter project
cp "lib/libllama.so" "$OUTPUT_DIR/"

echo "✅ libllama.so built and copied to: $OUTPUT_DIR"

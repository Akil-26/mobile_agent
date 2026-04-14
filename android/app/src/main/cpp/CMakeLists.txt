cmake_minimum_required(VERSION 3.18.1)

project(llama)

# Path to llama.cpp source
set(LLAMA_SRC_DIR "${CMAKE_SOURCE_DIR}/llama-src")

# Create llama.cpp static library
add_library(llama STATIC
    ${LLAMA_SRC_DIR}/src/llama.cpp
    ${LLAMA_SRC_DIR}/src/ggml.c
)

target_include_directories(llama PUBLIC
    ${LLAMA_SRC_DIR}/src
)

target_compile_options(llama PRIVATE
    -O3
    -std=c99
    -fPIC
)

# Create JNI binding library
add_library(llama_jni SHARED
    llama_jni.cpp
)

target_link_libraries(llama_jni
    llama
    log
)

target_include_directories(llama_jni PRIVATE
    ${LLAMA_SRC_DIR}/src
)

# Set architecture-specific optimization
if(ANDROID_ABI STREQUAL "arm64-v8a")
    target_compile_options(llama PRIVATE
        -march=armv8-a
    )
    target_compile_options(llama_jni PRIVATE
        -march=armv8-a
    )
endif()

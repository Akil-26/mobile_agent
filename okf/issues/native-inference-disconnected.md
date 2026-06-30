---
type: Issue
title: Native inference pipeline is fully disconnected
description: Local model download works; actual on-device inference never runs. Confirmed by tracing the full call chain.
tags: [bug, critical, blocking]
status: open
---

# Native inference pipeline is fully disconnected

Confirmed by tracing the full chain end to end on 2026-06-30.

## Chain of evidence

1. `android/app/src/main/jniLibs/arm64-v8a/libllama.so` is **9 bytes** — a
   placeholder, not a compiled library.
2. `LlamaService.kt` (Kotlin JNI wrapper) is well-written but **never
   instantiated** anywhere in the codebase — `getInstance()` is not called
   from `MainActivity.kt` or elsewhere.
3. `MainActivity.kt` registers exactly one channel,
   `com.mobile_agent/native_tools`, and it only handles the 18 device tools
   (calls, SMS, alarms, etc.) — no `run_inference`, no model-loading method.
4. `LocalModelService.dart` listens on a **different, mismatched** channel —
   `com.example.flutter_application_1/model_inference` — which doesn't exist
   on the Android side.
5. `_nativeAvailable` in `local_model_service.dart` is hardcoded `false` and
   never set `true` anywhere, so `_attemptNativeInference()` always returns
   `null` before even attempting the (mismatched) channel call.
6. Every chat response currently comes from `_generateFallbackResponse()` —
   simple keyword string-matching, not the model.

## Net effect

The app downloads a real 1.59GB Gemma-2-2B GGUF file, reports
`isLoaded == true`, and shows "✅ Local AI Ready — Running on-device
inference" — but no inference ever happens.

## Resolution direction

Replace the dead custom JNI path with the `fllama` Flutter plugin (maintained
llama.cpp bindings) rather than hand-rolling NDK/CMake/JNI from a 9-byte
stub. Tracked in [phase-1-local-model](../roadmap/phase-1-local-model.md).

## Related

- [local-model-service](../services/local-model-service.md)
- [native-bridge](../architecture/native-bridge.md)

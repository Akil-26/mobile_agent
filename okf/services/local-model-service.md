---
type: Service
title: LocalModelService
resource: lib/services/local_model_service.dart
description: Downloads a GGUF model file and is meant to run on-device inference. Download works; inference does not.
tags: [ai, on-device, broken]
---

# LocalModelService

## What works

Downloads `gemma-2-2b-it-Q4_K_M.gguf` (~1.59GB) from Hugging Face into the
app's documents directory, with resume support via HTTP Range headers and
progress callbacks. `isModelDownloaded()` / `deleteModel()` work correctly.

## What's broken

`chat()` is supposed to run real inference via a MethodChannel
(`com.example.flutter_application_1/model_inference`, method `run_inference`),
but:

1. That channel is never registered on the Android side (`MainActivity.kt`
   only registers `com.mobile_agent/native_tools`, which has no inference
   methods).
2. The Dart-side flag `_nativeAvailable` is hardcoded `false` and never
   flipped `true` anywhere in the codebase, so `_attemptNativeInference()`
   returns `null` immediately without ever calling the channel.
3. `_generateFallbackResponse()` then runs instead — simple keyword
   matching (e.g. "hello", "2+2"), not a model.

Full detail: [native-inference-disconnected](../issues/native-inference-disconnected.md).

## Related

- [ai-service](ai-service.md)
- Planned fix: [phase-1-local-model](../roadmap/phase-1-local-model.md)

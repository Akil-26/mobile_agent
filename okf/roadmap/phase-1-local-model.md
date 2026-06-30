---
type: RoadmapPhase
title: "Phase 1: Real local-model inference"
status: in-progress
description: Replace the dead JNI stub with a working on-device LLM pipeline.
tags: [roadmap, ai, on-device]
---

# Phase 1: Real local-model inference

## Goal

Real, working on-device chat — closes
[native-inference-disconnected](../issues/native-inference-disconnected.md).

## Decisions made

- Engine: `fllama` plugin (maintained llama.cpp bindings) instead of the
  hand-rolled JNI stub.
- Model: switching from Gemma-2-2B (1.59GB) to a smaller 1–1.5B model
  (e.g. Qwen2.5-1.5B-Instruct GGUF, Q4_K_M) for better phone performance.

## Steps

1. Add `fllama` to `pubspec.yaml`.
2. Point the downloader at the new smaller GGUF model URL.
3. Rewrite `LocalModelService.chat()` to call `fllama`'s API instead of the
   dead MethodChannel path.
4. Stream tokens into the chat UI instead of waiting for a full response.
5. Remove or repurpose the now-dead `LlamaService.kt` / `llama_jni.cpp` /
   `libllama.so` stub files.

## Related

- [local-model-service](../services/local-model-service.md)
- [ai-service](../services/ai-service.md)

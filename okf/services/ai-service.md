---
type: Service
title: AIService
resource: lib/services/ai_service.dart
description: Static dispatcher that picks between local model, Ollama, and offline mode.
tags: [ai, dispatcher]
---

# AIService

Static class. On `initialize()`, checks `OllamaService.checkConnection()` and
`LocalModelService.isModelDownloaded()`, then sets `currentMode` to one of
`AIMode.local`, `AIMode.ollama`, or `AIMode.offline` (local takes priority if
both are available).

`chat()` routes to whichever backend matches `currentMode`, with a fallback
from local to Ollama if the local model claims to be loaded but isn't
actually producing output.

## Depends on

- [local-model-service](local-model-service.md)
- [ollama-service](ollama-service.md)

## Used by

- ChatBloc — see [bloc-layer](../architecture/bloc-layer.md)

## Caveat

"Local mode" reporting `isLoaded == true` does not currently mean real
inference is happening — see
[native-inference-disconnected](../issues/native-inference-disconnected.md).

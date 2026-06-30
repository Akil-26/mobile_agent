---
type: Index
title: Services
description: Service classes in lib/services/ — what each one actually does.
---

# Services

- [ai-service](ai-service.md) — picks local vs Ollama vs offline mode
- [local-model-service](local-model-service.md) — on-device model download + (currently broken) inference
- [ollama-service](ollama-service.md) — talks to a desktop Ollama server over HTTP
- [tools-service](tools-service.md) — extracts and executes tool calls from model responses
- [tool-registry](tool-registry.md) — defines the 18 available device tools
- [native-platform-service](native-platform-service.md) — Dart-side wrapper for the native bridge

## Related

- [Architecture](../architecture/index.md)

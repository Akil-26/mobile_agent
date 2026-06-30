---
type: Service
title: OllamaService
resource: lib/services/ollama_service.dart
description: HTTP client for a desktop Ollama server, used as a fallback or alternative to the local model.
tags: [ai, ollama, http]
---

# OllamaService

Talks to an Ollama instance over HTTP (default desktop URL, user-configurable
in Settings). Used when no on-device model is downloaded, or as a fallback
when local inference fails.

## Known gap

The model picker in Settings lets the user select a model name, but earlier
analysis of this codebase found the selected model was not always being
propagated into `OllamaService.model` — worth re-checking after the BLoC
refactor, since this file predates it.

## Related

- [ai-service](ai-service.md)

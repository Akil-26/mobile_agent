---
type: Component
title: BLoC Layer
description: State management classes mediating between UI and services.
tags: [bloc, state-management]
---

# BLoC Layer

Three Cubits, each backed by an event/state pair, live in `lib/bloc/`:

- **ChatBloc** (`lib/bloc/chat/chat_bloc.dart`) — owns the message list,
  calls [AIService](../services/ai-service.md) to get responses, detects tool
  calls in the response via [ToolsService](../services/tools-service.md), and
  routes to confirmation or direct execution depending on the tool's
  `requiresConfirmation` flag.
- **SettingsBloc** (`lib/bloc/settings/settings_bloc.dart`) — manages
  AI mode, Ollama URL, and download state.
- **ToolBloc** (`lib/bloc/tools/tool_bloc.dart`) — drives the tools
  management/browser screen.

## Related

- [Services index](../services/index.md)
- [ai-service](../services/ai-service.md)
- [tools-service](../services/tools-service.md)

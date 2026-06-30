---
type: Index
title: Architecture
description: Layer breakdown of the app and how data flows between them.
---

# Architecture

```
UI (screens/widgets)
  -> BLoC (ChatBloc, SettingsBloc, ToolBloc)
    -> Services (AIService -> LocalModelService / OllamaService, ToolsService, ToolRegistry)
      -> Native bridge (MethodChannel: com.mobile_agent/native_tools)
        -> Android (MainActivity.kt: calls, SMS, alarms, contacts, file ops)
```

A second, currently-unwired native path exists for on-device LLM inference:
`LocalModelService` (Dart) expects a channel that `MainActivity.kt` never
registers, and the JNI/llama.cpp layer underneath it is unimplemented. See
[native-inference-disconnected](../issues/native-inference-disconnected.md).

## Layers

- [BLoC layer](bloc-layer.md)
- [Native bridge](native-bridge.md)

## Related

- [Services](../services/index.md)
- [Known issues](../issues/index.md)

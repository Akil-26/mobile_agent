---
type: Service
title: ToolsService
resource: lib/services/tools_service.dart
description: Parses tool calls out of model responses and executes them via the native bridge.
tags: [tools, agent-actions]
---

# ToolsService

Given a raw model response, `extractToolCall()` looks for a structured tool
invocation (tool name + args). If found, `ChatBloc` checks the matching
`ToolDefinition` from [tool-registry](tool-registry.md): tools flagged
`requiresConfirmation` go through a confirmation dialog first; others execute
immediately via `executeTool()`, which calls into
[native-platform-service](native-platform-service.md).

`describeToolResult()` turns the raw result into a human-readable line shown
back in chat.

## Flow

```
model response -> extractToolCall() -> ToolRegistry.getToolByName()
  -> [confirm?] -> executeTool() -> native bridge -> result shown in chat
```

## Related

- [tool-registry](tool-registry.md)
- [native-platform-service](native-platform-service.md)
- [bloc-layer](../architecture/bloc-layer.md)

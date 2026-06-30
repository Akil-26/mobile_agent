---
type: Service
title: ToolRegistry
resource: lib/services/tool_registry.dart
description: Static definitions of the 18 device tools the agent can call.
tags: [tools, registry]
---

# ToolRegistry

Defines `ToolDefinition`s (name, description, args schema, whether it needs
user confirmation) for every tool exposed over the
[native bridge](../architecture/native-bridge.md): `make_call`, `send_sms`,
`send_email`, `read_file`, `write_file`, `delete_file`, `list_files`,
`get_device_info`, `set_alarm`, `open_app`, `get_battery_status`,
`get_contacts`, `search_contacts`, plus permission tools.

This is the natural place to register new tools as the agent grows (Gmail
API actions, calendar, etc.) — see
[phase-2-app-integrations](../roadmap/phase-2-app-integrations.md).

## Related

- [tools-service](tools-service.md)
- [native-bridge](../architecture/native-bridge.md)

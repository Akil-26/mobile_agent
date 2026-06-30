---
type: Component
title: Native Bridge
description: MethodChannel connecting Dart to Android-native device capabilities.
tags: [android, kotlin, methodchannel]
---

# Native Bridge

Channel name: `com.mobile_agent/native_tools`, registered in
`android/app/src/main/kotlin/.../MainActivity.kt`, consumed from Dart in
`lib/services/native_platform_service.dart`.

## Working today

`make_call`, `send_sms`, `send_email` (via intent chooser), `read_file`,
`write_file`, `delete_file`, `list_files`, `get_device_info`, `set_alarm`,
`open_app`, `get_battery_status`, `get_contacts`, `search_contacts`,
`request_permissions`, `check_permission`.

## Not implemented despite being referenced elsewhere

`run_inference` / model loading — `LocalModelService.dart` calls a
**different, non-existent** channel (`com.example.flutter_application_1/model_inference`)
that `MainActivity.kt` never registers. See
[native-inference-disconnected](../issues/native-inference-disconnected.md).

## Related

- [native-platform-service](../services/native-platform-service.md)
- [tool-registry](../services/tool-registry.md)

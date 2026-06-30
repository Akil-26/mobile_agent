---
type: Service
title: NativePlatformService
resource: lib/services/native_platform_service.dart
description: Dart-side wrapper around the com.mobile_agent/native_tools MethodChannel.
tags: [native, methodchannel]
---

# NativePlatformService

Thin wrapper exposing each native tool (`makeCall`, `sendSms`, `setAlarm`,
etc.) as a Dart async function, calling
`MethodChannel('com.mobile_agent/native_tools')` underneath. Called by
[tools-service](tools-service.md) when executing a confirmed tool call.

## Related

- [native-bridge](../architecture/native-bridge.md)
- [tool-registry](tool-registry.md)

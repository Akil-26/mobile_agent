# Quick Reference Guide

## 🚀 Getting Started

### Run the App
```bash
cd c:\projects\Hackathon\flutter_application_1
flutter pub get
flutter run
```

### Key Entry Points
1. **main.dart** - App initialization with BLoCs
2. **ChatScreen** - Main UI (Menu → Tools to see tool browser)
3. **ToolsManagementScreen** - Browse all 18 tools

---

## 📖 Understanding the Code

### Model a User Flow

**Scenario**: User says "What's my battery?"

```
1. ChatScreen:
   - User types message
   - _sendMessage() called

2. ChatBloc:
   - sendMessage(text) emitted
   - Adds user message to _messages
   - Calls AIService.chat()

3. AIService:
   - Sends to local model or Ollama
   - Gets back: {"tool": "get_battery_status", "args": {}}

4. ChatBloc (back):
   - ToolsService.extractToolCall() finds JSON
   - ToolRegistry confirms tool exists
   - executeToolCall() called

5. ToolsService:
   - Recognizes "get_battery_status"
   - Calls NativePlatformService.getBatteryStatus()

6. NativePlatformService:
   - Invokes MethodChannel: "get_battery_status"

7. Android (Kotlin):
   - MainActivity receives call
   - getBatteryStatus() executed
   - Returns: {battery_percent: 85, is_charging: false}

8. Back to Dart:
   - ToolResult created
   - ChatBloc adds result message
   - UI updates with: "🔋 Battery: 85%"
```

---

## 🔍 Key Files to Know

### If you want to...

| Goal | File | Line | What to do |
|------|------|------|-----------|
| **Add a new tool** | `lib/services/tool_registry.dart` | ~30 | Add ToolDefinition to `allTools` list |
| **Handle tool execution** | `lib/services/tools_service.dart` | ~50 | Add case to `executeTool()` switch |
| **Bridge to Android** | `lib/services/native_platform_service.dart` | ~100 | Add new method calling MethodChannel |
| **Change tool behavior** | `lib/bloc/tools/tool_bloc.dart` | ~20 | Modify `executeToolCall()` |
| **Update LLM prompt** | `lib/services/tool_registry.dart` | ~120 | Update `generateSystemPrompt()` |
| **Add confirmation** | `lib/models/tool_definitions.dart` | ~15 | Set `requiresConfirmation: true` |
| **Change UI** | `lib/ui/screens/chat_screen.dart` | ~50 | Modify ChatScreen widgets |
| **Add new permission** | `ANDROID_SETUP.md` | ~130 | Add to AndroidManifest.xml |

---

## 🎯 Common Tasks

### Task 1: Make "Call Mom" Work

1. **Ollama/Local Model Side**
   - Ensure model is prompted to output: `{"tool": "make_call", "args": {"phone_number": "+1234567890"}}`

2. **Flutter Side (happens automatically)**
   - ToolsService.extractToolCall() finds the JSON
   - ToolRegistry confirms "make_call" exists & requiresConfirmation=true
   - Shows ToolConfirmationDialog

3. **User Approves**
   - ChatBloc.executeToolCall() called
   - NativePlatformService.makeCall() invoked

4. **Android Side**
   - MainActivity.makeCall() opens dialer
   - Returns success

### Task 2: Add "Send Email" Tool

1. **Add to ToolRegistry** (tool_registry.dart):
```dart
ToolDefinition(
  name: 'send_email',
  description: 'Send an email message',
  category: 'communication',
  requiresConfirmation: true,
  schema: {
    'recipient': {'type': 'string'},
    'subject': {'type': 'string'},
    'message': {'type': 'string'},
  },
)
```

2. **Add to ToolsService** (tools_service.dart):
```dart
case 'send_email':
  return NativePlatformService.sendEmail(
    args['recipient'] ?? '',
    args['subject'] ?? '',
    args['message'] ?? '',
  );
```

3. **Add to NativePlatformService** (native_platform_service.dart):
```dart
static Future<ToolResult> sendEmail(String to, String subject, String message) async {
  try {
    final result = await methodChannel.invokeMethod('send_email', {
      'to': to,
      'subject': subject,
      'message': message,
    });
    return ToolResult(toolName: 'send_email', success: true);
  } catch (e) {
    return ToolResult(toolName: 'send_email', success: false, error: e.toString());
  }
}
```

4. **Add to MainActivity.kt** (ANDROID_SETUP.md implementation):
```kotlin
"send_email" -> sendEmail(
  call.argument("to"),
  call.argument("subject"),
  call.argument("message"),
  result
)

private fun sendEmail(to: String?, subject: String?, message: String?, result: MethodChannel.Result) {
  try {
    val intent = Intent(Intent.ACTION_SEND).apply {
      type = "message/rfc822"
      putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
      putExtra(Intent.EXTRA_SUBJECT, subject)
      putExtra(Intent.EXTRA_TEXT, message)
    }
    startActivity(Intent.createChooser(intent, "Send Email"))
    result.success(mapOf("success" to true))
  } catch (e: Exception) {
    result.error("EXCEPTION", e.message, null)
  }
}
```

Done! 4 places, ~5 minutes total.

---

## 🐛 Debugging Tips

### Tool not appearing in browser?
```
1. Check ToolRegistry.allTools contains it ✓
2. Check tool name in schema matches exactly ✓
3. Hot reload the app (not just restart)
```

### Tool not executing?
```
1. Check call flow: ChatBloc → ToolsService → NativePlatformService
2. Add print statements: print('Executing tool: ${toolCall.tool}')
3. Check MethodChannel name: "com.example.ai_assistant/tools"
4. Check MainActivity has the method
```

### Confirmation dialog not showing?
```
1. Verify: ToolDefinition.requiresConfirmation = true
2. Check: ChatBloc emits ChatToolConfirmationRequired state
3. Verify: ChatScreen has BlocListener for this state
```

### Permission denied on Android?
```
1. Check: AndroidManifest.xml has <uses-permission>
2. Check: User granted at runtime (system dialog)
3. Check: Permission level (CALL_PHONE requires special handling)
```

---

## 📊 State Diagram

```
ChatInitial
    ↓
ChatLoading
    ↓
ChatInitialized / ChatMessagesUpdated
    ├→ ChatToolConfirmationRequired (user must approve)
    │           ↓
    │    [User taps Confirm]
    │           ↓
    ├→ ChatToolExecuting
    │           ↓
    ├→ ChatToolExecuted
    │           ↓
    └→ ChatMessagesUpdated (show result)

Any state → ChatError (on exception)
```

---

## 🔗 Data Model Relationships

```
Message
├─ content: String
├─ isUser: bool
└─ timestamp: DateTime

ToolCall
├─ tool: String (name)
└─ args: Map<String, dynamic>

ToolDefinition
├─ name: String
├─ description: String
├─ category: String
├─ requiresConfirmation: bool
└─ schema: Map

ToolResult
├─ toolName: String
├─ success: bool
├─ error: String?
└─ data: Map?
```

---

## 🎓 Learning Path

Start here:

1. **Read**: PROJECT_SUMMARY.md (big picture)
2. **Read**: ARCHITECTURE.md (components)
3. **Read**: TOOLS_IMPLEMENTATION_GUIDE.md (how tools work)
4. **Read**: main.dart → understand structure
5. **Read**: ChatBloc → understand state flow
6. **Read**: ChatScreen → understand UI
7. **Try**: Add a simple tool (get_battery_status already works as example)
8. **Extend**: Add more tools based on Android integration

---

## 📱 Testing on Device

```bash
# Connect Android device or start emulator
adb devices

# Run app
flutter run

# View logs
flutter logs

# If issues, clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## 🎉 You're Ready!

Your app is fully functional. To verify:

1. Open app
2. Say any chat message (if AI connected)
3. Tap menu (three dots) → Tools
4. Browse 18 tools by category
5. Tap any tool to execute it
6. See confirmation dialog (for sensitive tools)
7. Watch result display

**Congratulations!** 🚀

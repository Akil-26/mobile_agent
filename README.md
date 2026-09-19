# Private AI Assistant (Mobile Agent)

Welcome to the **Mobile Agent** project. This is a private, offline-first AI Assistant built using **Flutter** and **Kotlin**. It is designed to run real on-device LLM inference (or interface with a desktop Ollama instance) and execute system-level operations (calls, SMS, emails, alarms, contacts, and file management) directly on an Android device using native Kotlin bindings.

---

## 🏗️ Architecture Overview

The app is built using a structured architecture separating UI, Business Logic (BLoC/Cubit), AI Service routing, and Platform-Specific Native Integrations.

Below is the workflow diagram showing how user inputs trigger AI reasoning, local or network inference, tool generation, and native device action execution:

```mermaid
graph TD
    User([User Input]) --> ChatScreen[ChatScreen / UI]
    ChatScreen --> ChatBloc[ChatBloc / State Management]
    ChatBloc --> AIService[AIService / Router]
    
    AIService -- Local Mode --> LocalModelService[LocalModelService / llama_cpp_dart]
    AIService -- Online Mode --> OllamaService[OllamaService / HTTP API]
    
    LocalModelService -- Real On-Device Inference --> libllama[libllama.so / llama.cpp]
    
    ChatBloc -- Response Parsing (Extract JSON Tool Call) --> ToolsService[ToolsService]
    ToolsService -- Execute Tool --> NativePlatformService[NativePlatformService / MethodChannel]
    NativePlatformService -- Invoke Method Channel --> MainActivity[MainActivity.kt / Kotlin]
    
    MainActivity -- Native API Calls --> AndroidOS[Android OS Services / Intents / Files]
    AndroidOS -- Result Callback --> MainActivity
    MainActivity -- Return Map --> NativePlatformService
    NativePlatformService --> ChatBloc
    ChatBloc --> ChatScreen
```

---

## 🛠️ Core Technologies Used

| Technology / Library | Version / Source | Description |
| :--- | :--- | :--- |
| **Flutter SDK** | `>=3.9.2` | Core cross-platform UI framework |
| **Dart SDK** | Compatible with SDK 3.9.2 | Language core |
| **flutter_bloc** | `^8.1.3` (with `bloc` `^8.1.1`) | UI state management using Cubits |
| **llama_cpp_dart** | `^0.2.2` | FFI bindings to load and query native `llama.cpp` shared libraries |
| **http** | `^1.2.0` | For HTTP requests, used to query local Ollama instance tags/chat APIs |
| **path_provider** | `^2.1.2` | Used to obtain local documents directory for downloading and storing GGUF models |
| **path** | `^1.9.0` | Filesystem path utility helper |
| **Kotlin / Android Native** | Kotlin stdlib / Android SDK | Native Android implementation handling MethodChannels, Intents, and System Services |
| **CMake & Android NDK** | NDK 27.0.12077973 / CMake 3.22.1 | Cross-compiles native C++ `llama.cpp` code to a shared `.so` library for Android |

---

## 📂 Project Structure & Walkthrough

### 1. Dart codebase (`lib/`)

* **`lib/main.dart`**: Entry point of the application. It initializes the Flutter binding, configures MaterialApp (dark theme, Material 3), wraps the app in a `MultiBlocProvider` providing `ChatBloc`, `SettingsBloc`, and `ToolBloc`, and opens the `ChatScreen` as the default route.
* **`lib/models/`**: Defines structures and schemas.
  * `ai_mode.dart`: Defines the `AIMode` enum (`local`, `ollama`, `offline`).
  * `message.dart`: Schema representing a single message in the chat conversation (content text, isUser flag).
  * `tool_definitions.dart` & `tool_args.dart`: Data structures that represent what tools exist (`ToolDefinition`), how they are parsed and called (`ToolCall`), and what they return (`ToolResult`).
* **`lib/services/`**: Holds core business/integration logic.
  * [ai_service.dart](file:///c:/projects/Mobile_apps/Mobile_agent/lib/services/ai_service.dart): Determines whether the app is offline, connected to Ollama, or using the local downloaded model. Routes user messages accordingly.
  * [local_model_service.dart](file:///c:/projects/Mobile_apps/Mobile_agent/lib/services/local_model_service.dart): Handles downloading the Qwen2.5 GGUF model file, loading it into an isolate via `llama_cpp_dart`, handling stream subscriptions, unloading, and deletion.
  * [ollama_service.dart](file:///c:/projects/Mobile_apps/Mobile_agent/lib/services/ollama_service.dart): Connects to Ollama API `http://localhost:11434` to pull available models, check availability, and query chat endpoints.
  * [native_platform_service.dart](file:///c:/projects/Mobile_apps/Mobile_agent/lib/services/native_platform_service.dart): The Dart client wrapper for the `MethodChannel` (`com.mobile_agent/native_tools`).
  * [tool_registry.dart](file:///c:/projects/Mobile_apps/Mobile_agent/lib/services/tool_registry.dart): Declares all available tools, categories, safety configuration (whether confirmation dialog is required), and formats the LLM system prompt.
  * [tools_service.dart](file:///c:/projects/Mobile_apps/Mobile_agent/lib/services/tools_service.dart): RegEx pattern matching to extract JSON formatted tool invocations (e.g. `{"tool": "make_call", "args": {"phoneNumber": "..."}}`) from LLM responses and routes executions.
* **`lib/bloc/`**: Contains state logic separating the UI from pure logic:
  * `chat/`: Chat state management (welcome text, typing state, tool extraction, confirmation events, and app state streams).
  * `settings/`: Handles state of downloading and loading local AI model.
  * `tools/`: Manages standalone tool testing and registry details.
* **`lib/ui/`**: User interface components.
  * `screens/`: Contains the visual pages (`chat_screen.dart`, `profile_screen.dart`, `settings_screen.dart`, `tools_management_screen.dart`, `tools_test_screen.dart`).
  * `widgets/`: Small, reusable elements such as input bars, message boxes, typing animators, and tool execution dialog overlays.

### 2. Native Android Codebase (`android/`)
* **`MainActivity.kt`** (located at `android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt`): Instantiates the MethodChannel `com.mobile_agent/native_tools` and routes the methods to direct Android OS API calls.

---

## 📱 Native Tool Capabilities (MethodChannel Mappings)

The assistant uses specific JSON parameters to call native APIs through the method channel handler. Here are the tools implemented in Kotlin (`MainActivity.kt`):

### 📞 Communication
* **`make_call`**: Invokes `Intent.ACTION_CALL`. Requires `android.permission.CALL_PHONE`. Runs with safety confirmation.
* **`send_sms`**: Uses `SmsManager.getDefault().sendTextMessage`. Requires `android.permission.SEND_SMS`. Runs with safety confirmation.
* **`send_email`**: Opens mail apps using `Intent.ACTION_SENDTO` with recipient, subject, and body parameters.

### 📂 File System Operations
* **`read_file`**: Reads text files from the device path.
* **`write_file`**: Writes custom text contents to a path (creates directories automatically). Runs with safety confirmation.
* **`delete_file`**: Deletes a file. Runs with safety confirmation.
* **`list_files`**: Lists files, directory paths, size, directory flags, and modification timestamps. Defaults to the application's external files directory if no path is provided.

### ⚙️ System & Productivity
* **`get_device_info`**: Retrieves hardware parameters (manufacturer, model, OS release, SDK version, board, brand).
* **`get_battery_status`**: Queries `BatteryManager` for current capacity percentage and charging state.
* **`set_alarm`**: Invokes Android's `AlarmClock.ACTION_SET_ALARM` with specified hour, minute, and tag.
* **`open_app`**: Starts an installed application by its package name (e.g. `com.whatsapp`, `com.google.android.youtube`) using `PackageManager.getLaunchIntentForPackage`.
* **`get_contacts`**: Reads display names and telephone numbers. Requires `android.permission.READ_CONTACTS`. Runs with safety confirmation.
* **`search_contacts`**: Performs a database query using SQL `LIKE` operator matching display names against a search term.

### 🛡️ Permissions
* **`check_permission`**: Queries if a specific permission string is currently granted.
* **`request_permissions`**: Invokes standard Android runtime prompt to request permission arrays.

---

## 🤖 AI Model Configuration

The application operates in three configurations based on setup:

1. **Local Mode (Offline-First)**:
   * **Target Model**: `Qwen2.5-1.5B-Instruct-GGUF` (Quantized: `qwen2.5-1.5b-instruct-q4_k_m.gguf` - ~1.12 GB). Chosen because it fits well in mobile memory constraints (~1GB RAM overhead) while maintaining strong instruction-following skills.
   * **Host Server**: Hugging Face (downloaded inside application documents directory).
   * **Template format**: ChatML (`<|im_start|>system...`, `<|im_start|>user...`, `<|im_start|>assistant...`).
2. **Ollama Mode**:
   * **Target Model**: `gemma3:1b` (Default in configuration, editable).
   * **Network URL**: `http://localhost:11434` (Ollama desktop server).
3. **Offline Mode**:
   * Safe fallback state prompting the user to either download the local model or configure Ollama.

---

## 🛠️ Step-by-Step Native Library Build Instructions

Because `llama_cpp_dart` acts as a bridge to `llama.cpp`, it is critical to cross-compile and bundle the native C++ library (`libllama.so`) for Android `arm64-v8a` before executing `flutter run`.

### 📋 Prerequisites
1. **Android NDK**: NDK version `27.0.12077973` (or similar) installed on your system.
2. **CMake**: Installed and added to environment variables.
3. **C++ Compilation Chain**: `make` or `ninja`.
4. **Git**: To download the `llama.cpp` source code.

### 🚀 Running the Compilation

Choose one of the two helper scripts provided in the root directory:

#### Option A: Direct Bash (Linux/macOS Host)
Ensure `ANDROID_NDK_HOME` environment variable points to your NDK path, then execute:
```bash
export ANDROID_NDK_HOME=$HOME/Android/Sdk/ndk/27.0.12077973
chmod +x build-llama-android.sh
./build-llama-android.sh
```

#### Option B: WSL Environment (Windows Host)
If compiling from Windows via WSL, execute the WSL build helper:
```bash
chmod +x build-llama-wsl.sh
./build-llama-wsl.sh
```
*Note: Make sure paths specified at the top of the shell script match your system directories.*

### 📂 Where does the file go?
The scripts clone `llama.cpp` into a temporary directory `/tmp/llama_cpp_src`, run `cmake` configurations, compile the codebase, and copy the produced shared library (`libllama.so`) into:
```
android/app/src/main/jniLibs/arm64-v8a/libllama.so
```
Once `libllama.so` is in place, you can build/run the Flutter app on an Android device:
```bash
flutter pub get
flutter run
```

---

## 🔍 Troubleshooting & Key Learnings for Developers

* **Library Not Found Error**: If the application crashes on launch when loading the local model, double-check that `libllama.so` is correctly compiled and located under `android/app/src/main/jniLibs/arm64-v8a/libllama.so`.
* **Method Channel Name**: The MethodChannel name `com.mobile_agent/native_tools` must match exactly in both [native_platform_service.dart](file:///c:/projects/Mobile_apps/Mobile_agent/lib/services/native_platform_service.dart) and [MainActivity.kt](file:///c:/projects/Mobile_apps/Mobile_agent/android/app/src/main/kotlin/com/example/flutter_application_1/MainActivity.kt).
* **Package Name Mismatch**: The Android package name is configured as `com.example.flutter_application_1` in Gradle, while the workspace is named `Mobile_agent`. Be cautious when refactoring names to avoid breaking MethodChannel registrations.
* **Isolate Execution**: `llama_cpp_dart` operates local LLM inference in separate Dart Isolates (`LlamaParent`) to ensure compilation and heavy processing do not lock up or stutter the Flutter main UI Thread.

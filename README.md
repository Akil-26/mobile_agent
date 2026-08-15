# Mobile Agent 🤖

**An on-device AI agent app that runs large language models locally — no internet, no cloud, no data leaving your device.**

Built with Flutter and powered by [llama.cpp](https://github.com/ggerganov/llama.cpp) (via `llama_cpp_dart`), Mobile Agent lets you chat with an LLM directly on your phone, desktop, or browser — fast, private, and fully offline-capable.

---

## ✨ Features

- 🧠 **On-device inference** — runs GGUF-format LLMs locally using llama.cpp, no API keys or internet required
- 🔒 **Private by design** — your conversations never leave your device
- 📱 **Cross-platform** — Android, iOS, Windows, macOS, Linux, and Web from a single codebase
- ⚡ **BLoC state management** — predictable, testable app state
- 📦 **Local model storage** — download and manage models directly on-device

## 🛠 Tech Stack

| Layer | Tool |
|---|---|
| Framework | [Flutter](https://flutter.dev) |
| LLM Inference | [llama_cpp_dart](https://pub.dev/packages/llama_cpp_dart) |
| State Management | flutter_bloc / bloc |
| Networking | http |
| Storage | path_provider |

## 📋 Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart SDK `^3.9.2`)
- Android Studio / Xcode (for mobile builds)
- A GGUF model file (e.g. from [Hugging Face](https://huggingface.co/models?library=gguf))

## 🚀 Getting Started

1. **Clone the repo**
   ```bash
   git clone https://github.com/Akil-26/mobile_agent.git
   cd mobile_agent
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Build the native llama.cpp library (Android)**
   ```bash
   ./build-llama-android.sh
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
mobile_agent/
├── android/       # Android platform code
├── ios/           # iOS platform code
├── linux/         # Linux desktop platform code
├── macos/         # macOS desktop platform code
├── windows/       # Windows desktop platform code
├── web/           # Web platform code
├── lib/           # Main Dart/Flutter application code
├── test/          # Unit and widget tests
└── build-llama-android.sh  # Script to build llama.cpp native libs for Android
```

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/Akil-26/mobile_agent/issues).

## 📄 License

_Add your license here (e.g. MIT, Apache 2.0)._

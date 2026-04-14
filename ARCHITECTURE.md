# Perfect Flutter App Structure with BLoC

## Folder Structure

```
lib/
├── main.dart                           # App entry point with MultiBlocProvider
│
├── models/                             # Data models layer
│   ├── message.dart                   # Message model
│   ├── ai_mode.dart                   # AI Mode enum
│   └── index.dart                     # Model exports
│
├── services/                          # Business logic services (Logical Layer)
│   ├── ai_service.dart                # Unified AI service (uses Local & Ollama)
│   ├── local_model_service.dart       # Local model management
│   ├── ollama_service.dart            # Ollama integration
│   └── index.dart                     # Service exports
│
├── bloc/                              # State Management (BLoC)
│   ├── chat/
│   │   ├── chat_bloc.dart             # Chat business logic & state management
│   │   ├── chat_event.dart            # Chat events
│   │   └── chat_state.dart            # Chat states
│   │
│   ├── settings/
│   │   ├── settings_bloc.dart         # Settings business logic
│   │   ├── settings_event.dart        # Settings events
│   │   └── settings_state.dart        # Settings states
│   │
│   └── index.dart                     # BLoC exports
│
├── ui/                                # User Interface Layer
│   ├── screens/
│   │   ├── chat_screen.dart           # Main chat UI
│   │   ├── profile_screen.dart        # User profile UI
│   │   ├── settings_screen.dart       # Settings UI
│   │   └── index.dart                 # Screen exports
│   │
│   ├── widgets/
│   │   ├── message_bubble.dart        # Message display widget
│   │   ├── typing_indicator.dart      # Typing animation
│   │   ├── input_area.dart            # Message input widget
│   │   ├── empty_state.dart           # Empty chat state
│   │   ├── profile_widgets.dart       # Profile UI components
│   │   ├── settings_section.dart      # Settings section widget
│   │   └── index.dart                 # Widget exports
│   │
│   └── (other UI subfolder)           # Can add themes, dialogs, etc.
│
└── (other root levels)                # config/, constants/, utils/ as needed
```

## Architecture Layers

### 1. **Models Layer** (`lib/models/`)
- Pure data classes
- Enums for app states
- No dependencies on other layers

### 2. **Services Layer** (`lib/services/`)
- **Logical/Business Logic Layer**
- Handles API calls and external integrations
- LocalModelService: Model file management
- OllamaService: Ollama API communication
- AIService: Unified AI interface

### 3. **BLoC Layer** (`lib/bloc/`)
- **State Management Layer**
- ChatBloc: Manages chat messages and conversation state
- SettingsBloc: Manages app settings state
- Events handle user actions
- States represent UI states
- Clean separation of concerns

### 4. **UI Layer** (`lib/ui/`)
- **Presentation Layer**
- Screens: Full-page widgets
- Widgets: Reusable UI components
- Widgets listen to BLoC state and update accordingly
- Widgets emit events through BLoC for user interactions

## Data Flow

```
User Action → Widget emits Event → BLoC processes Event
→ BLoC calls Service → Service performs logic → BLoC emits State
→ Widget rebuilds with new State
```

## Benefits

✅ **Clean Architecture**: Clear separation of concerns
✅ **Scalable**: Easy to add new features without touching existing code
✅ **Testable**: Each layer can be tested independently
✅ **Maintainable**: Changes are isolated to their layers
✅ **Reusable**: Widgets and services are reusable components
✅ **Type-Safe**: Strong typing with Dart

## Key Points

- **BLoC Pattern**: Separates business logic from UI
- **Logical Layer**: Services handle all business logic
- **UI Layer**: Pure presentation, no business logic
- **State Management**: Using flutter_bloc for reactive state
- **Exports**: Each folder has index.dart for clean imports

/// Base class for all tool arguments
abstract class ToolArgs {
  Map<String, dynamic> toJson();
}

/// Communication Tools Args
class MakeCallArgs extends ToolArgs {
  final String phoneNumber;
  final bool direct;

  MakeCallArgs({
    required this.phoneNumber,
    this.direct = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    'direct': direct,
  };
}

class SendSmsArgs extends ToolArgs {
  final String phoneNumber;
  final String message;

  SendSmsArgs({
    required this.phoneNumber,
    required this.message,
  });

  @override
  Map<String, dynamic> toJson() => {
    'phone_number': phoneNumber,
    'message': message,
  };
}

class ShareTextArgs extends ToolArgs {
  final String text;
  final String? package;

  ShareTextArgs({
    required this.text,
    this.package,
  });

  @override
  Map<String, dynamic> toJson() => {
    'text': text,
    'package': package,
  };
}

/// Productivity Tools Args
class SetAlarmArgs extends ToolArgs {
  final int hour;
  final int minute;
  final String? label;
  final bool skipUi;

  SetAlarmArgs({
    required this.hour,
    required this.minute,
    this.label,
    this.skipUi = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'hour': hour,
    'minute': minute,
    'label': label,
    'skip_ui': skipUi,
  };
}

class SetTimerArgs extends ToolArgs {
  final int seconds;
  final String? label;
  final bool skipUi;

  SetTimerArgs({
    required this.seconds,
    this.label,
    this.skipUi = false,
  });

  @override
  Map<String, dynamic> toJson() => {
    'seconds': seconds,
    'label': label,
    'skip_ui': skipUi,
  };
}

/// Media Tools Args
class OpenCameraArgs extends ToolArgs {
  @override
  Map<String, dynamic> toJson() => {};
}

class OpenAppArgs extends ToolArgs {
  final String package;

  OpenAppArgs({required this.package});

  @override
  Map<String, dynamic> toJson() => {'package': package};
}

/// Settings Tools Args
class OpenSettingsArgs extends ToolArgs {
  final String target;

  OpenSettingsArgs({required this.target});

  @override
  Map<String, dynamic> toJson() => {'target': target};
}

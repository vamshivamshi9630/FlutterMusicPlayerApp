import 'package:flutter/foundation.dart';

/// Central place for sensitive config injected via --dart-define
/// ❌ Never hardcode secrets here
class Secrets {
  static const String googleClientId =
  String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');

  static const String googleClientSecret =
  String.fromEnvironment('GOOGLE_CLIENT_SECRET', defaultValue: '');

  static bool get isConfigured {
    // Android / iOS rely on google-services.json / plist
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return true;
    }

    // Web + Desktop still require both
    return googleClientId.isNotEmpty && googleClientSecret.isNotEmpty;
  }


  static void validate() {
    if (!isConfigured) {
      throw Exception(
        'Missing GOOGLE_CLIENT_ID or GOOGLE_CLIENT_SECRET.\n'
            'Run app with:\n'
            '--dart-define=GOOGLE_CLIENT_ID=xxx '
            '--dart-define=GOOGLE_CLIENT_SECRET=yyy',
      );
    }
  }
}
